-- Verify schemas/patients/tables/patients on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'patients' AND table_name = 'patients'
  )), 'Table patients.patients does not exist';
END $$;
