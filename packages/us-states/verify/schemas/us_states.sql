-- Verify schemas/us_states on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata
    WHERE schema_name = 'us_states'
  )), 'Schema us_states does not exist';
END $$;
