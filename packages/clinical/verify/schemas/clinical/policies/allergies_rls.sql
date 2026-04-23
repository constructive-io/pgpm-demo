-- Verify schemas/clinical/policies/allergies_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'clinical.allergies'::regclass),
    'RLS not enabled on clinical.allergies';
END $$;
