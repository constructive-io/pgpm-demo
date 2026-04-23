-- Verify schemas/clinical/tables/conditions on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'clinical' AND table_name = 'conditions'
  )), 'Table clinical.conditions does not exist';
END $$;
