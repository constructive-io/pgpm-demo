-- Revert schemas/lab_orders/policies/lab_orders_rls from pg

DROP POLICY lab_orders_modify ON lab_orders.lab_orders;
DROP POLICY lab_orders_select ON lab_orders.lab_orders;

ALTER TABLE lab_orders.lab_orders NO FORCE ROW LEVEL SECURITY;
ALTER TABLE lab_orders.lab_orders DISABLE ROW LEVEL SECURITY;
