/**
 * Adversarial RLS tests for prescriptions.
 *
 * Actors: Alice (legit), Bob (legit), Mallory (attacker).
 *
 * Patients come from __fixtures__/patients.csv via `pg.loadCsv` — change the CSV
 * to add more patients, no test code changes required. Prescriptions are seeded
 * inline by joining the medications catalog the module already ships.
 *
 * Toggle `currentUser` below and re-run to watch RLS gate different identities.
 */
import * as path from 'path';
import { getConnections, PgTestClient, seed } from 'pgsql-test';

let pg: PgTestClient;
let db: PgTestClient;
let teardown: () => Promise<void>;

// Deterministic UUIDs keep CSV rows and test assertions in lock-step.
const alice = {
  id: '11111111-1111-4111-8111-111111111111',
  role: 'patient' as const,
};
const bob = {
  id: '22222222-2222-4222-8222-222222222222',
  role: 'patient' as const,
};
const mallory = {
  id: '99999999-9999-4999-8999-999999999999',
  role: 'patient' as const,
};

// ═══════════════════════════════════════════════════════════════════════════
// TOGGLE ME — swap currentUser between alice / bob / mallory and re-run.
//   alice   → the "currentUser sees Alice's scripts" test passes.
//   bob     → that same test fails (RLS hides Alice's rows).
//   mallory → same test fails (RLS hides them from her too).
//
// The two Mallory-specific tests below pass regardless of this toggle.
// ═══════════════════════════════════════════════════════════════════════════
const currentUser = alice;
// const currentUser = bob;
// const currentUser = mallory;

beforeAll(async () => {
  ({ pg, db, teardown } = await getConnections({}, [seed.pgpm()]));

  // authenticated role is created by the patients module; grant membership
  // to the app_user that pgsql-test created before the seed.
  await pg.query(`GRANT authenticated TO app_user`);

  // Bulk-load patients from CSV. COPY bypasses RLS — safe via `pg` (superuser).
  await pg.loadCsv({
    'patients.patients': path.join(__dirname, '__fixtures__/patients.csv'),
  });

  // Seed prescriptions by joining to the pre-seeded medications catalog.
  //   Alice  → 2 scripts (amoxicillin, atorvastatin)
  //   Bob    → 1 script  (metformin)
  //   Mallory → 0 scripts — she's the attacker with no legitimate history.
  await pg.query(
    `INSERT INTO prescriptions.prescriptions
       (patient_id, medication_id, dosage, route, frequency, quantity, refills)
     SELECT $1::uuid, id, '500 mg', 'oral', 'TID x 7d', 21, 0
       FROM medications.medications WHERE generic_name = 'amoxicillin'
     UNION ALL
     SELECT $1::uuid, id, '20 mg',  'oral', 'QD',       30, 3
       FROM medications.medications WHERE generic_name = 'atorvastatin'
     UNION ALL
     SELECT $2::uuid, id, '500 mg', 'oral', 'BID',      60, 2
       FROM medications.medications WHERE generic_name = 'metformin';`,
    [alice.id, bob.id],
  );
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

function actAs(user: { id: string; role: string }) {
  db.setContext({
    role: 'authenticated',
    'app.role': user.role,
    'app.user_id': user.id,
  });
}

describe('prescriptions adversarial RLS', () => {
  // ───────────────────────────────────────────────────────────────────────
  // Toggle-driven test: only Alice should see Alice's prescriptions.
  // Flip `currentUser` at the top to watch RLS filter them out for others.
  // ───────────────────────────────────────────────────────────────────────
  it("currentUser can read Alice's two prescriptions", async () => {
    actAs(currentUser);
    const r = await db.query(
      `SELECT m.generic_name
       FROM prescriptions.prescriptions rx
       JOIN medications.medications m ON m.id = rx.medication_id
       WHERE rx.patient_id = $1
       ORDER BY m.generic_name`,
      [alice.id],
    );
    expect(r.rows.map((row: { generic_name: string }) => row.generic_name)).toEqual([
      'amoxicillin',
      'atorvastatin',
    ]);
  });

  // ───────────────────────────────────────────────────────────────────────
  // Mallory cannot write for someone else — WITH CHECK + clinician-only
  // write policy both reject the INSERT.
  // ───────────────────────────────────────────────────────────────────────
  it('Mallory cannot forge a prescription in Alice\'s name', async () => {
    actAs(mallory);
    const amox = await pg.query(
      `SELECT id FROM medications.medications WHERE generic_name = 'amoxicillin' LIMIT 1`,
    );
    const point = 'mallory_forge';
    await db.savepoint(point);
    await expect(
      db.query(
        `INSERT INTO prescriptions.prescriptions
           (patient_id, medication_id, dosage, route, frequency, quantity)
         VALUES ($1, $2, '500 mg', 'oral', 'PRN', 30)`,
        [alice.id, amox.rows[0].id],
      ),
    ).rejects.toThrow(/row-level security/i);
    await db.rollback(point);
  });

  // ───────────────────────────────────────────────────────────────────────
  // Even with a known row ID, RLS returns zero rows to a non-owner.
  // This proves the USING policy isn't bypassable via guessed primary keys.
  // ───────────────────────────────────────────────────────────────────────
  it('Mallory sees zero rows even when querying Alice\'s row ID directly', async () => {
    const alice_rx = await pg.query(
      `SELECT id FROM prescriptions.prescriptions WHERE patient_id = $1 LIMIT 1`,
      [alice.id],
    );

    actAs(mallory);
    const r = await db.query(
      `SELECT id FROM prescriptions.prescriptions WHERE id = $1`,
      [alice_rx.rows[0].id],
    );
    expect(r.rowCount).toBe(0);
  });
});
