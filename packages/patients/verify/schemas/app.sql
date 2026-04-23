-- Verify schemas/app on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'app'
  )), 'Schema app does not exist';
END $$;
