-- Verify roles/authenticated on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated')),
    'Role authenticated does not exist';
END $$;
