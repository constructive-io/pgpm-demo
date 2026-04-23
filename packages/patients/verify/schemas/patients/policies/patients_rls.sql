-- Verify schemas/patients/policies/patients_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'patients.patients'::regclass), 'RLS not enabled on patients.patients';
  ASSERT (SELECT count(*) FROM pg_policies
          WHERE schemaname = 'patients' AND tablename = 'patients') >= 4,
    'Expected at least 4 policies on patients.patients';
END $$;
