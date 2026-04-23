-- Revert schemas/patients/policies/patients_rls from pg

DROP POLICY patients_delete ON patients.patients;
DROP POLICY patients_update ON patients.patients;
DROP POLICY patients_insert ON patients.patients;
DROP POLICY patients_select ON patients.patients;

ALTER TABLE patients.patients NO FORCE ROW LEVEL SECURITY;
ALTER TABLE patients.patients DISABLE ROW LEVEL SECURITY;
