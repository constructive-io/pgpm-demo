-- Deploy schemas/patients/policies/patient_contacts_rls to pg
-- requires: schemas/patients/tables/patient_contacts
-- requires: schemas/app/functions/current_user_id
-- requires: schemas/app/functions/is_clinician_or_admin
-- requires: roles/authenticated

ALTER TABLE patients.patient_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients.patient_contacts FORCE ROW LEVEL SECURITY;

CREATE POLICY patient_contacts_select ON patients.patient_contacts
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY patient_contacts_modify ON patients.patient_contacts
  FOR ALL TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );
