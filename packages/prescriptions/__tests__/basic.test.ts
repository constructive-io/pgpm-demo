import { getConnections, PgTestClient, seed } from 'pgsql-test';

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

let aliceId: string;
let bobId: string;
let amoxId: string;
let oxycodoneId: string;

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

  const meds = await pg.query(
    `SELECT id, generic_name FROM medications.medications
     WHERE generic_name IN ('amoxicillin', 'oxycodone')`,
  );
  amoxId = meds.rows.find((r: { generic_name: string }) => r.generic_name === 'amoxicillin').id;
  oxycodoneId = meds.rows.find((r: { generic_name: string }) => r.generic_name === 'oxycodone').id;
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

describe('prescriptions RLS (diamond: medications + scheduling both required)', () => {
  it("Alice sees only her own prescriptions, never Bob's", async () => {
    asClinician();
    await db.query(
      `INSERT INTO prescriptions.prescriptions
        (patient_id, medication_id, dosage, route, frequency, quantity, refills)
       VALUES
        ($1, $3, '500 mg', 'oral', 'TID x 7d', 21, 0),
        ($2, $4, '5 mg',   'oral', 'PRN',      10, 0)`,
      [aliceId, bobId, amoxId, oxycodoneId],
    );

    asPatient(aliceId);
    const aliceView = await db.query(`
      SELECT m.generic_name, rx.dosage
      FROM prescriptions.prescriptions rx
      JOIN medications.medications m ON m.id = rx.medication_id
    `);
    expect(aliceView.rows).toHaveLength(1);
    expect(aliceView.rows[0].generic_name).toBe('amoxicillin');
    expect(aliceView.rows[0].dosage).toBe('500 mg');
  });

  it('Clinician sees every prescription across patients', async () => {
    asClinician();
    await db.query(
      `INSERT INTO prescriptions.prescriptions
        (patient_id, medication_id, dosage, route, frequency, quantity)
       VALUES
        ($1, $3, '500 mg', 'oral', 'TID x 7d', 21),
        ($2, $4, '5 mg',   'oral', 'PRN',      10)`,
      [aliceId, bobId, amoxId, oxycodoneId],
    );

    const r = await db.query(`SELECT count(*) FROM prescriptions.prescriptions`);
    expect(Number(r.rows[0].count)).toBeGreaterThanOrEqual(2);
  });

  it('Patient cannot self-prescribe (clinician-only write policy)', async () => {
    asPatient(aliceId);
    const point = 'patient_self_prescribe';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO prescriptions.prescriptions
          (patient_id, medication_id, dosage, route, frequency, quantity)
         VALUES ($1, $2, '10 mg', 'oral', 'PRN', 30)`,
        [aliceId, oxycodoneId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });

  it('Foreign key to medications catalog is enforced (diamond join works)', async () => {
    asClinician();
    const point = 'invalid_med_fk';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO prescriptions.prescriptions
          (patient_id, medication_id, dosage, route, frequency, quantity)
         VALUES ($1, '00000000-0000-0000-0000-000000000000', '1 mg', 'oral', 'QD', 1)`,
        [aliceId],
      ),
    ).rejects.toThrow(/foreign key/i);
    await db.rollback(point);
  });
});
