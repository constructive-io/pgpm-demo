-- Deploy schemas/patients/policies/patients_rls to pg
-- requires: schemas/patients/tables/patients
-- requires: schemas/app/functions/current_user_id
-- requires: schemas/app/functions/is_clinician_or_admin
-- requires: roles/authenticated

ALTER TABLE patients.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients.patients FORCE ROW LEVEL SECURITY;

CREATE POLICY patients_select ON patients.patients
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR id = app.current_user_id()
  );

CREATE POLICY patients_insert ON patients.patients
  FOR INSERT TO authenticated
  WITH CHECK (app.is_clinician_or_admin());

CREATE POLICY patients_update ON patients.patients
  FOR UPDATE TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR id = app.current_user_id()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
    OR id = app.current_user_id()
  );

CREATE POLICY patients_delete ON patients.patients
  FOR DELETE TO authenticated
  USING (app.current_role() = 'admin');
