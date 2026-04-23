-- Deploy schemas/lab_results/policies/lab_results_rls to pg
-- requires: schemas/lab_results/tables/lab_results

ALTER TABLE lab_results.lab_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_results.lab_results FORCE ROW LEVEL SECURITY;

-- Patient access checked by joining through lab_orders
CREATE POLICY lab_results_select ON lab_results.lab_results
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR EXISTS (
      SELECT 1 FROM lab_orders.lab_orders o
      WHERE o.id = lab_order_id
        AND o.patient_id = app.current_user_id()
    )
  );

CREATE POLICY lab_results_modify ON lab_results.lab_results
  FOR ALL TO authenticated
  USING (app.is_clinician_or_admin())
  WITH CHECK (app.is_clinician_or_admin());
