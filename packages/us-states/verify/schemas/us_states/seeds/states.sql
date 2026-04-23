-- Verify schemas/us_states/seeds/states on pg

DO $$
BEGIN
  ASSERT (SELECT count(*) FROM us_states.states) = 51,
    'Expected 51 rows in us_states.states (50 states + DC)';
  ASSERT (SELECT count(*) FROM us_states.states WHERE is_state) = 50,
    'Expected 50 rows where is_state = true';
END $$;
