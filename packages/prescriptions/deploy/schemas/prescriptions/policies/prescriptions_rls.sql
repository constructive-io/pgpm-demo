-- Deploy schemas/prescriptions/policies/prescriptions_rls to pg
-- requires: schemas/prescriptions/tables/prescriptions

ALTER TABLE prescriptions.prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions.prescriptions FORCE ROW LEVEL SECURITY;

CREATE POLICY prescriptions_select ON prescriptions.prescriptions
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY prescriptions_modify ON prescriptions.prescriptions
  FOR ALL TO authenticated
  USING (app.is_clinician_or_admin())
  WITH CHECK (app.is_clinician_or_admin());
