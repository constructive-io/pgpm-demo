-- Verify schemas/clinical/policies/conditions_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'clinical.conditions'::regclass),
    'RLS not enabled on clinical.conditions';
END $$;
