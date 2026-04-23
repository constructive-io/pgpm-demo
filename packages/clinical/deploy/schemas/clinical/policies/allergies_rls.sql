-- Deploy schemas/clinical/policies/allergies_rls to pg
-- requires: schemas/clinical/tables/allergies

ALTER TABLE clinical.allergies ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.allergies FORCE ROW LEVEL SECURITY;

CREATE POLICY allergies_select ON clinical.allergies
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY allergies_modify ON clinical.allergies
  FOR ALL TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );
