-- Verify schemas/documents/policies/documents_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'documents.documents'::regclass),
    'RLS not enabled on documents.documents';
END $$;
