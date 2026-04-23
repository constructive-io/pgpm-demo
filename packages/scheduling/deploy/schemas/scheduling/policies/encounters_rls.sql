-- Deploy schemas/scheduling/policies/encounters_rls to pg
-- requires: schemas/scheduling/tables/encounters

ALTER TABLE scheduling.encounters ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduling.encounters FORCE ROW LEVEL SECURITY;

CREATE POLICY encounters_select ON scheduling.encounters
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY encounters_modify ON scheduling.encounters
  FOR ALL TO authenticated
  USING (app.is_clinician_or_admin())
  WITH CHECK (app.is_clinician_or_admin());
