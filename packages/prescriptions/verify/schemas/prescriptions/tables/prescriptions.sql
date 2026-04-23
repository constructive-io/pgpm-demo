-- Verify schemas/prescriptions/tables/prescriptions on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'prescriptions' AND table_name = 'prescriptions'
  )), 'Table prescriptions.prescriptions does not exist';
END $$;
