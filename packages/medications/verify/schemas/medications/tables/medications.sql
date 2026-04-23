-- Verify schemas/medications/tables/medications on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'medications' AND table_name = 'medications'
  )), 'Table medications.medications does not exist';
END $$;
