-- Verify schemas/patients on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'patients'
  )), 'Schema patients does not exist';
END $$;
