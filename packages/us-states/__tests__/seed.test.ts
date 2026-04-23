import { getConnections, PgTestClient, seed } from 'pgsql-test';

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

describe('us_states seed', () => {
  it('seeds 51 rows — 50 states + DC', async () => {
    const r = await pg.query(`SELECT count(*) FROM us_states.states`);
    expect(Number(r.rows[0].count)).toBe(51);
  });

  it('seeds exactly 50 rows where is_state is true', async () => {
    const r = await pg.query(
      `SELECT count(*) FROM us_states.states WHERE is_state = true`,
    );
    expect(Number(r.rows[0].count)).toBe(50);
  });

  it('flags DC as a non-state federal district', async () => {
    const r = await pg.query(
      `SELECT is_state, admitted_on FROM us_states.states WHERE code = 'DC'`,
    );
    expect(r.rows[0].is_state).toBe(false);
    expect(r.rows[0].admitted_on).toBeNull();
  });

  it('distributes states across 4 census regions', async () => {
    const r = await pg.query(
      `SELECT region, count(*)::int AS n FROM us_states.states GROUP BY region ORDER BY region`,
    );
    const byRegion = Object.fromEntries(
      r.rows.map((row: { region: string; n: number }) => [row.region, row.n]),
    );
    expect(Object.keys(byRegion).sort()).toEqual(['Midwest', 'Northeast', 'South', 'West']);
    const total = Object.values(byRegion).reduce(
      (acc: number, n) => acc + (n as number),
      0,
    );
    expect(total).toBe(51);
  });
});
