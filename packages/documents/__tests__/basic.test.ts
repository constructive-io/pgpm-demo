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

describe('documents RLS', () => {
  it("Alice can read her own clinical notes but cannot see Bob's", async () => {
    asClinician();
    await db.query(
      `INSERT INTO documents.documents (patient_id, kind, title, body)
       VALUES ($1, 'clinical_note', 'Annual Physical', 'Patient in good health.'),
              ($2, 'clinical_note', 'Follow-up',        'Blood sugar elevated.')`,
      [aliceId, bobId],
    );

    asPatient(aliceId);
    const aliceView = await db.query(`SELECT title FROM documents.documents`);
    expect(aliceView.rows).toHaveLength(1);
    expect(aliceView.rows[0].title).toBe('Annual Physical');

    asPatient(bobId);
    const bobView = await db.query(`SELECT title FROM documents.documents`);
    expect(bobView.rows).toHaveLength(1);
    expect(bobView.rows[0].title).toBe('Follow-up');
  });

  it('Clinician sees every document', async () => {
    asClinician();
    await db.query(
      `INSERT INTO documents.documents (patient_id, kind, title, body)
       VALUES ($1, 'clinical_note', 'Note A', 'a'),
              ($2, 'clinical_note', 'Note B', 'b')`,
      [aliceId, bobId],
    );

    const r = await db.query(`SELECT count(*) FROM documents.documents`);
    expect(Number(r.rows[0].count)).toBeGreaterThanOrEqual(2);
  });

  it('Patient cannot upload a document to themselves (clinician-only write)', async () => {
    asPatient(aliceId);
    const point = 'patient_doc_denied';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO documents.documents (patient_id, kind, title, body)
         VALUES ($1, 'other', 'Malicious note', 'I am healthy, really')`,
        [aliceId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });

  it('Patient absolutely cannot upload a document targeting another patient', async () => {
    asPatient(aliceId);
    const point = 'forged_doc';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO documents.documents (patient_id, kind, title, body)
         VALUES ($1, 'other', 'Forged note on Bob', 'fake')`,
        [bobId],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });
});
