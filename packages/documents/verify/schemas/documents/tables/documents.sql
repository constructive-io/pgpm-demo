-- Verify schemas/documents/tables/documents on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'documents' AND table_name = 'documents'
  )), 'Table documents.documents does not exist';
END $$;
