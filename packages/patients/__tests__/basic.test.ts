import { getConnections, PgTestClient, seed } from 'pgsql-test';

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

let aliceId: string;
let bobId: string;

beforeAll(async () => {
  ({ pg, db, teardown } = await getConnections({}, [seed.pgpm()]));

  // pgsql-test creates `app_user` before our seed deploys the `authenticated`
  // role, so the initial grant is a no-op. Re-grant now that the role exists
  // so `db` can SET LOCAL ROLE authenticated via setContext().
  await pg.query(`GRANT authenticated TO app_user`);

  const res = await pg.query(`
    INSERT INTO patients.patients (first_name, last_name, date_of_birth)
    VALUES ('Alice', 'Anderson', '1980-01-01'),
           ('Bob',   'Brown',    '1985-05-05')
    RETURNING id
  `);
  aliceId = res.rows[0].id;
  bobId = res.rows[1].id;
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

describe('patients RLS', () => {
  it('Alice-as-patient sees only her own row', async () => {
    asPatient(aliceId);
    const r = await db.query(`SELECT id, first_name FROM patients.patients`);
    expect(r.rows).toHaveLength(1);
    expect(r.rows[0].first_name).toBe('Alice');
  });

  it('Alice cannot read Bob even with an explicit WHERE id = bob', async () => {
    asPatient(aliceId);
    const r = await db.query(`SELECT id FROM patients.patients WHERE id = $1`, [bobId]);
    expect(r.rowCount).toBe(0);
  });

  it('a clinician sees every patient', async () => {
    asClinician();
    const r = await db.query(`SELECT id FROM patients.patients`);
    expect(r.rowCount).toBeGreaterThanOrEqual(2);
  });

  it('a patient cannot create a new patient record', async () => {
    asPatient(aliceId);
    const point = 'patient_insert_denied';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO patients.patients (first_name, last_name, date_of_birth)
         VALUES ('Mallory','M','2000-01-01')`,
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });

  it('a clinician can create a new patient', async () => {
    asClinician();
    const r = await db.query(
      `INSERT INTO patients.patients (first_name, last_name, date_of_birth)
       VALUES ('Carol','Chen','1990-01-01') RETURNING id`,
    );
    expect(r.rows[0].id).toBeDefined();
  });

  it('patients cannot delete — the delete policy requires admin role', async () => {
    asPatient(aliceId);
    const r = await db.query(`DELETE FROM patients.patients WHERE id = $1`, [aliceId]);
    expect(r.rowCount).toBe(0);
  });

  it('a patient with no user_id set sees nothing', async () => {
    asPatient(''); // no user id
    const r = await db.query(`SELECT count(*) FROM patients.patients`);
    expect(Number(r.rows[0].count)).toBe(0);
  });
});

describe('patient_contacts RLS', () => {
  it("Alice sees only her own contacts; clinician sees everyone's", async () => {
    asClinician();
    await db.query(
      `INSERT INTO patients.patient_contacts (patient_id, kind, name, phone)
       VALUES ($1, 'emergency', 'Alice ER Contact', '555-0001'),
              ($2, 'emergency', 'Bob ER Contact',   '555-0002')`,
      [aliceId, bobId],
    );

    const clinicianView = await db.query(`SELECT name FROM patients.patient_contacts`);
    expect(clinicianView.rowCount).toBeGreaterThanOrEqual(2);

    asPatient(aliceId);
    const aliceView = await db.query(`SELECT name FROM patients.patient_contacts`);
    expect(aliceView.rows).toHaveLength(1);
    expect(aliceView.rows[0].name).toBe('Alice ER Contact');
  });
});
