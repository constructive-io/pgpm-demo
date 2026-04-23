-- Verify schemas/lab_orders/policies/lab_orders_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'lab_orders.lab_orders'::regclass),
    'RLS not enabled on lab_orders.lab_orders';
END $$;
