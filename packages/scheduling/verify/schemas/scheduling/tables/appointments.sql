-- Verify schemas/scheduling/tables/appointments on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'scheduling' AND table_name = 'appointments'
  )), 'Table scheduling.appointments does not exist';
END $$;
