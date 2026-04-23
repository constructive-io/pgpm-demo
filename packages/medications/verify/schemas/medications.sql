-- Verify schemas/medications on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'medications'
  )), 'Schema medications does not exist';
END $$;
