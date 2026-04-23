-- Verify schemas/app/functions/is_clinician_or_admin on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'app' AND p.proname = 'is_clinician_or_admin'
  )), 'Function app.is_clinician_or_admin does not exist';
END $$;
