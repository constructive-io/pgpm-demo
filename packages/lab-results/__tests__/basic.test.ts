import { getConnections, PgTestClient, seed } from 'pgsql-test';

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

let aliceId: string;
let bobId: string;
let aliceOrderId: string;
let bobOrderId: string;

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

  const orders = await pg.query(
    `INSERT INTO lab_orders.lab_orders (patient_id, test_code, test_name, status)
     VALUES ($1, 'A1C', 'Hemoglobin A1C', 'resulted'),
            ($2, 'A1C', 'Hemoglobin A1C', 'resulted')
     RETURNING id`,
    [aliceId, bobId],
  );
  aliceOrderId = orders.rows[0].id;
  bobOrderId = orders.rows[1].id;
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

describe('lab_results RLS (across the lab_orders chain)', () => {
  it("Alice sees her lab result via her order, but not Bob's", async () => {
    asClinician();
    await db.query(
      `INSERT INTO lab_results.lab_results (lab_order_id, analyte, value_numeric, unit, flag)
       VALUES ($1, 'HbA1c', 5.9, '%',  'normal'),
              ($2, 'HbA1c', 9.1, '%',  'high')`,
      [aliceOrderId, bobOrderId],
    );

    asPatient(aliceId);
    const aliceView = await db.query(`SELECT value_numeric, flag FROM lab_results.lab_results`);
    expect(aliceView.rows).toHaveLength(1);
    expect(Number(aliceView.rows[0].value_numeric)).toBeCloseTo(5.9);
    expect(aliceView.rows[0].flag).toBe('normal');

    asPatient(bobId);
    const bobView = await db.query(`SELECT value_numeric, flag FROM lab_results.lab_results`);
    expect(bobView.rows).toHaveLength(1);
    expect(Number(bobView.rows[0].value_numeric)).toBeCloseTo(9.1);
    expect(bobView.rows[0].flag).toBe('high');
  });

  it('Clinician sees every lab result', async () => {
    asClinician();
    await db.query(
      `INSERT INTO lab_results.lab_results (lab_order_id, analyte, value_numeric, unit, flag)
       VALUES ($1, 'HbA1c', 6.0, '%', 'normal'),
              ($2, 'HbA1c', 9.2, '%', 'high')`,
      [aliceOrderId, bobOrderId],
    );

    const r = await db.query(`SELECT count(*) FROM lab_results.lab_results`);
    expect(Number(r.rows[0].count)).toBeGreaterThanOrEqual(2);
  });

  it('Patient cannot write lab results (clinician-only)', async () => {
    asPatient(aliceId);
    const point = 'patient_lab_result_denied';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO lab_results.lab_results (lab_order_id, analyte, value_numeric, unit, flag)
         VALUES ($1, 'HbA1c', 4.0, '%', 'normal')`,
        [aliceOrderId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });
});
