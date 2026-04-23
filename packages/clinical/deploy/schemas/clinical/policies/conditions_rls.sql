-- Deploy schemas/clinical/policies/conditions_rls to pg
-- requires: schemas/clinical/tables/conditions

ALTER TABLE clinical.conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.conditions FORCE ROW LEVEL SECURITY;

CREATE POLICY conditions_select ON clinical.conditions
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY conditions_modify ON clinical.conditions
  FOR ALL TO authenticated
  USING (app.is_clinician_or_admin())
  WITH CHECK (app.is_clinician_or_admin());
