-- Verify schemas/lab_results/policies/lab_results_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'lab_results.lab_results'::regclass),
    'RLS not enabled on lab_results.lab_results';
END $$;
