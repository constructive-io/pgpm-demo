-- Verify schemas/lab_results on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'lab_results'
  )), 'Schema lab_results does not exist';
END $$;
