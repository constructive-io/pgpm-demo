-- Verify schemas/prescriptions on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'prescriptions'
  )), 'Schema prescriptions does not exist';
END $$;
