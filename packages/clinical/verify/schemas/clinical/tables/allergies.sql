-- Verify schemas/clinical/tables/allergies on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'clinical' AND table_name = 'allergies'
  )), 'Table clinical.allergies does not exist';
END $$;
