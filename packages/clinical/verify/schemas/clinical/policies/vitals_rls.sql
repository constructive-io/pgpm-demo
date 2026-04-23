-- Verify schemas/clinical/policies/vitals_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'clinical.vitals'::regclass),
    'RLS not enabled on clinical.vitals';
END $$;
