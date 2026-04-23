-- Verify schemas/clinical/tables/vitals on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'clinical' AND table_name = 'vitals'
  )), 'Table clinical.vitals does not exist';
END $$;
