-- Deploy schemas/lab_orders/policies/lab_orders_rls to pg
-- requires: schemas/lab_orders/tables/lab_orders

ALTER TABLE lab_orders.lab_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_orders.lab_orders FORCE ROW LEVEL SECURITY;

CREATE POLICY lab_orders_select ON lab_orders.lab_orders
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY lab_orders_modify ON lab_orders.lab_orders
  FOR ALL TO authenticated
  USING (app.is_clinician_or_admin())
  WITH CHECK (app.is_clinician_or_admin());
