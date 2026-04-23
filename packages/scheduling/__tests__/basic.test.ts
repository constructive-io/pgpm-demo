import { getConnections, PgTestClient, seed } from 'pgsql-test';

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

let aliceId: string;
let bobId: string;
let aliceApptId: string;
let bobApptId: string;

beforeAll(async () => {
  ({ pg, db, teardown } = await getConnections({}, [seed.pgpm()]));

  await pg.query(`GRANT authenticated TO app_user`);

  const patients = await pg.query(`
    INSERT INTO patients.patients (first_name, last_name, date_of_birth)
    VALUES ('Alice', 'Anderson', '1980-01-01'),
           ('Bob',   'Brown',    '1985-05-05')
    RETURNING id
  `);
  aliceId = patients.rows[0].id;
  bobId = patients.rows[1].id;

  const appts = await pg.query(
    `INSERT INTO scheduling.appointments (patient_id, scheduled_at, reason)
     VALUES ($1, now() + interval '1 day', 'Annual physical'),
            ($2, now() + interval '2 days', 'Follow-up')
     RETURNING id`,
    [aliceId, bobId],
  );
  aliceApptId = appts.rows[0].id;
  bobApptId = appts.rows[1].id;
});

afterAll(async () => {
  await teardown();
});

beforeEach(async () => {
  await pg.beforeEach();
  await db.beforeEach();
});

afterEach(async () => {
  await db.afterEach();
  await pg.afterEach();
});

function asPatient(userId: string) {
  db.setContext({
    role: 'authenticated',
    'app.role': 'patient',
    'app.user_id': userId,
  });
}

function asClinician() {
  db.setContext({
    role: 'authenticated',
    'app.role': 'clinician',
    'app.user_id': '',
  });
}

describe('appointments RLS', () => {
  it('Alice sees only her own appointment', async () => {
    asPatient(aliceId);
    const r = await db.query(`SELECT id FROM scheduling.appointments`);
    expect(r.rows).toHaveLength(1);
    expect(r.rows[0].id).toBe(aliceApptId);
  });

  it("Alice cannot read Bob's appointment by ID", async () => {
    asPatient(aliceId);
    const r = await db.query(`SELECT id FROM scheduling.appointments WHERE id = $1`, [bobApptId]);
    expect(r.rowCount).toBe(0);
  });

  it('Clinician sees every appointment', async () => {
    asClinician();
    const r = await db.query(`SELECT id FROM scheduling.appointments`);
    expect(r.rowCount).toBeGreaterThanOrEqual(2);
  });

  it('Alice can self-schedule a new appointment for herself', async () => {
    asPatient(aliceId);
    const r = await db.query(
      `INSERT INTO scheduling.appointments (patient_id, scheduled_at, reason)
       VALUES ($1, now() + interval '5 days', 'Self-booked visit') RETURNING id`,
      [aliceId],
    );
    expect(r.rows[0].id).toBeDefined();
  });

  it('Alice CANNOT schedule an appointment on behalf of Bob', async () => {
    asPatient(aliceId);
    const point = 'cross_patient_insert';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO scheduling.appointments (patient_id, scheduled_at, reason)
         VALUES ($1, now() + interval '5 days', 'Mallory trying to spoof Bob')`,
        [bobId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });
});

describe('encounters RLS', () => {
  it('Clinician-only writes: patient cannot start an encounter', async () => {
    asPatient(aliceId);
    const point = 'patient_encounter_denied';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO scheduling.encounters (patient_id, chief_complaint)
         VALUES ($1, 'Self-reported headache')`,
        [aliceId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });

  it('Patient can READ their own encounter once clinician creates it', async () => {
    asClinician();
    const enc = await db.query(
      `INSERT INTO scheduling.encounters (patient_id, chief_complaint)
       VALUES ($1, 'Cough 5 days') RETURNING id`,
      [aliceId],
    );
    const encId = enc.rows[0].id;

    asPatient(aliceId);
    const r = await db.query(`SELECT id FROM scheduling.encounters WHERE id = $1`, [encId]);
    expect(r.rows).toHaveLength(1);

    asPatient(bobId);
    const r2 = await db.query(`SELECT id FROM scheduling.encounters WHERE id = $1`, [encId]);
    expect(r2.rowCount).toBe(0);
  });
});
