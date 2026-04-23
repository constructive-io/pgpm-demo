-- Verify schemas/prescriptions/policies/prescriptions_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'prescriptions.prescriptions'::regclass),
    'RLS not enabled on prescriptions.prescriptions';
END $$;
