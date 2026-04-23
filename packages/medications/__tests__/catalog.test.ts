import { getConnections, PgTestClient, seed } from 'pgsql-test';

// medications is a shared reference catalog — no RLS.
// This test uses `pg` because there's no RLS to exercise; we're verifying
// the catalog structure, seed data, and PUBLIC grant.
let pg: PgTestClient;
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ pg, teardown } = await getConnections({}, [seed.pgpm()]));
});

afterAll(async () => {
  await teardown();
});

beforeEach(async () => {
  await pg.beforeEach();
});

afterEach(async () => {
  await pg.afterEach();
});

describe('medications catalog', () => {
  it('seeds common medications', async () => {
    const r = await pg.query(`SELECT count(*) FROM medications.medications`);
    expect(Number(r.rows[0].count)).toBeGreaterThanOrEqual(10);
  });

  it('exposes well-known drugs via generic_name index', async () => {
    const r = await pg.query(
      `SELECT generic_name FROM medications.medications WHERE lower(generic_name) = 'metformin'`,
    );
    expect(r.rows).toHaveLength(1);
  });

  it('flags controlled substances with a DEA schedule', async () => {
    const r = await pg.query(
      `SELECT generic_name, schedule FROM medications.medications WHERE is_controlled = true`,
    );
    expect(r.rowCount).toBeGreaterThanOrEqual(2);
    for (const row of r.rows) {
      expect(row.schedule).toMatch(/^(I{1,3}|IV|V)$/);
    }
  });

  it('grants SELECT on the catalog to PUBLIC (shared reference data — no RLS)', async () => {
    const r = await pg.query(
      `SELECT grantee FROM information_schema.role_table_grants
       WHERE table_schema = 'medications' AND table_name = 'medications' AND privilege_type = 'SELECT'`,
    );
    const grantees = r.rows.map((row: { grantee: string }) => row.grantee);
    expect(grantees).toContain('PUBLIC');
  });

  it('does NOT enable RLS on the catalog table', async () => {
    const r = await pg.query(
      `SELECT relrowsecurity FROM pg_class WHERE oid = 'medications.medications'::regclass`,
    );
    expect(r.rows[0].relrowsecurity).toBe(false);
  });
});
