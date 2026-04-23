import { getConnections, PgTestClient, seed } from 'pgsql-test';

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

let aliceId: string;
let bobId: string;

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

describe('conditions RLS', () => {
  it('Alice sees only her own conditions', async () => {
    asClinician();
    await db.query(
      `INSERT INTO clinical.conditions (patient_id, description, status)
       VALUES ($1, 'Hypertension', 'active'),
              ($2, 'Type 2 Diabetes', 'active')`,
      [aliceId, bobId],
    );

    asPatient(aliceId);
    const r = await db.query(`SELECT description FROM clinical.conditions`);
    expect(r.rows).toHaveLength(1);
    expect(r.rows[0].description).toBe('Hypertension');
  });

  it('Clinician-only writes: patient cannot add a condition to themselves', async () => {
    asPatient(aliceId);
    const point = 'patient_condition_denied';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO clinical.conditions (patient_id, description)
         VALUES ($1, 'Self-diagnosed fake condition')`,
        [aliceId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });
});

describe('allergies RLS', () => {
  it("Alice can record her own allergies but cannot see Bob's", async () => {
    asPatient(aliceId);
    await db.query(
      `INSERT INTO clinical.allergies (patient_id, allergen, severity)
       VALUES ($1, 'Penicillin', 'severe')`,
      [aliceId],
    );

    asClinician();
    await db.query(
      `INSERT INTO clinical.allergies (patient_id, allergen, severity)
       VALUES ($1, 'Shellfish', 'moderate')`,
      [bobId],
    );

    asPatient(aliceId);
    const r = await db.query(`SELECT allergen FROM clinical.allergies`);
    expect(r.rows).toHaveLength(1);
    expect(r.rows[0].allergen).toBe('Penicillin');
  });

  it('Alice CANNOT add an allergy for Bob (WITH CHECK enforces row ownership)', async () => {
    asPatient(aliceId);
    const point = 'cross_patient_allergy';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO clinical.allergies (patient_id, allergen, severity)
         VALUES ($1, 'Sneaky injection on Bob', 'moderate')`,
        [bobId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });
});

describe('vitals RLS', () => {
  it('Clinicians record vitals; patients read their own only', async () => {
    asClinician();
    await db.query(
      `INSERT INTO clinical.vitals (patient_id, heart_rate_bpm, systolic_bp, diastolic_bp, temperature_c)
       VALUES ($1, 72, 120, 80, 36.7),
              ($2, 88, 145, 92, 37.1)`,
      [aliceId, bobId],
    );

    asPatient(aliceId);
    const aliceView = await db.query(`SELECT heart_rate_bpm FROM clinical.vitals`);
    expect(aliceView.rows).toHaveLength(1);
    expect(aliceView.rows[0].heart_rate_bpm).toBe(72);

    asPatient(bobId);
    const bobView = await db.query(`SELECT heart_rate_bpm FROM clinical.vitals`);
    expect(bobView.rows).toHaveLength(1);
    expect(bobView.rows[0].heart_rate_bpm).toBe(88);
  });

  it('Patients cannot record their own vitals', async () => {
    asPatient(aliceId);
    const point = 'patient_vitals_denied';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO clinical.vitals (patient_id, heart_rate_bpm)
         VALUES ($1, 200)`,
        [aliceId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });
});
