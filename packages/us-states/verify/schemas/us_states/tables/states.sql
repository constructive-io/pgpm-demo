-- Verify schemas/us_states/tables/states on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'us_states' AND table_name = 'states'
  )), 'Table us_states.states does not exist';
END $$;
