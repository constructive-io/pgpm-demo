-- Verify schemas/documents on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'documents'
  )), 'Schema documents does not exist';
END $$;
