-- Verify schemas/lab_orders on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'lab_orders'
  )), 'Schema lab_orders does not exist';
END $$;
