-- Verify schemas/app/functions/current_user_id on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'app' AND p.proname = 'current_user_id'
  )), 'Function app.current_user_id does not exist';
END $$;
