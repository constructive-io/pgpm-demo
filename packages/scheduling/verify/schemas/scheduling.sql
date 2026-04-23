-- Verify schemas/scheduling on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'scheduling'
  )), 'Schema scheduling does not exist';
END $$;
