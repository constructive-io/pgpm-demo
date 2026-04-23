-- Verify schemas/lab_orders/tables/lab_orders on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'lab_orders' AND table_name = 'lab_orders'
  )), 'Table lab_orders.lab_orders does not exist';
END $$;
