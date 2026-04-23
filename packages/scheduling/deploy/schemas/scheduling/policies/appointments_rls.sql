-- Deploy schemas/scheduling/policies/appointments_rls to pg
-- requires: schemas/scheduling/tables/appointments

ALTER TABLE scheduling.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduling.appointments FORCE ROW LEVEL SECURITY;

CREATE POLICY appointments_select ON scheduling.appointments
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY appointments_modify ON scheduling.appointments
  FOR ALL TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );
