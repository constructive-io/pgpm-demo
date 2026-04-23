-- Verify schemas/scheduling/policies/encounters_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'scheduling.encounters'::regclass),
    'RLS not enabled on scheduling.encounters';
END $$;
