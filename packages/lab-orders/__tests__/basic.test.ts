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

describe('lab_orders RLS', () => {
  it('Alice sees only her own lab orders', async () => {
    asClinician();
    await db.query(
      `INSERT INTO lab_orders.lab_orders (patient_id, test_code, test_name)
       VALUES ($1, 'CBC',   'Complete Blood Count'),
              ($2, 'BMP',   'Basic Metabolic Panel'),
              ($1, 'A1C',   'Hemoglobin A1C')`,
      [aliceId, bobId],
    );

    asPatient(aliceId);
    const aliceView = await db.query(
      `SELECT test_code FROM lab_orders.lab_orders ORDER BY test_code`,
    );
    expect(aliceView.rowCount).toBe(2);
    expect(aliceView.rows.map((r: { test_code: string }) => r.test_code)).toEqual(['A1C', 'CBC']);

    asPatient(bobId);
    const bobView = await db.query(`SELECT test_code FROM lab_orders.lab_orders`);
    expect(bobView.rowCount).toBe(1);
    expect(bobView.rows[0].test_code).toBe('BMP');
  });

  it('Clinician sees every lab order', async () => {
    asClinician();
    await db.query(
      `INSERT INTO lab_orders.lab_orders (patient_id, test_code, test_name)
       VALUES ($1, 'LIPID', 'Lipid Panel'),
              ($2, 'TSH',   'Thyroid Stimulating Hormone')`,
      [aliceId, bobId],
    );

    const r = await db.query(`SELECT count(*) FROM lab_orders.lab_orders`);
    expect(Number(r.rows[0].count)).toBeGreaterThanOrEqual(2);
  });

  it('Patients cannot order their own labs (clinician-only write policy)', async () => {
    asPatient(aliceId);
    const point = 'patient_lab_order_denied';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO lab_orders.lab_orders (patient_id, test_code, test_name)
         VALUES ($1, 'SELF', 'Self-ordered test')`,
        [aliceId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });
});
