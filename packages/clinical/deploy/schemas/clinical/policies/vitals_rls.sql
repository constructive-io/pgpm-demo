-- Deploy schemas/clinical/policies/vitals_rls to pg
-- requires: schemas/clinical/tables/vitals

ALTER TABLE clinical.vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.vitals FORCE ROW LEVEL SECURITY;

CREATE POLICY vitals_select ON clinical.vitals
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY vitals_modify ON clinical.vitals
  FOR ALL TO authenticated
  USING (app.is_clinician_or_admin())
  WITH CHECK (app.is_clinician_or_admin());
