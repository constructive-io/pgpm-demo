-- Verify schemas/app/functions/current_role on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'app' AND p.proname = 'current_role'
  )), 'Function app.current_role does not exist';
END $$;
