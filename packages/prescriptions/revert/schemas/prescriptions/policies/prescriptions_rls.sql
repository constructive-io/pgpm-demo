-- Revert schemas/prescriptions/policies/prescriptions_rls from pg

DROP POLICY prescriptions_modify ON prescriptions.prescriptions;
DROP POLICY prescriptions_select ON prescriptions.prescriptions;

ALTER TABLE prescriptions.prescriptions NO FORCE ROW LEVEL SECURITY;
ALTER TABLE prescriptions.prescriptions DISABLE ROW LEVEL SECURITY;
