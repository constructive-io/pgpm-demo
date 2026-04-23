-- Revert schemas/scheduling/policies/appointments_rls from pg

DROP POLICY appointments_modify ON scheduling.appointments;
DROP POLICY appointments_select ON scheduling.appointments;

ALTER TABLE scheduling.appointments NO FORCE ROW LEVEL SECURITY;
ALTER TABLE scheduling.appointments DISABLE ROW LEVEL SECURITY;
