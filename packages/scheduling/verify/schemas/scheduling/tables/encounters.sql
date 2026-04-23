-- Verify schemas/scheduling/tables/encounters on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'scheduling' AND table_name = 'encounters'
  )), 'Table scheduling.encounters does not exist';
END $$;
