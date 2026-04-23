-- Verify schemas/scheduling/policies/appointments_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'scheduling.appointments'::regclass),
    'RLS not enabled on scheduling.appointments';
END $$;
