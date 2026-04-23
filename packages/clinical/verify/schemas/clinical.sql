-- Verify schemas/clinical on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'clinical'
  )), 'Schema clinical does not exist';
END $$;
