-- Verify schemas/lab_results/tables/lab_results on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'lab_results' AND table_name = 'lab_results'
  )), 'Table lab_results.lab_results does not exist';
END $$;
