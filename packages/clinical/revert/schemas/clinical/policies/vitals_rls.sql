-- Revert schemas/clinical/policies/vitals_rls from pg

DROP POLICY vitals_modify ON clinical.vitals;
DROP POLICY vitals_select ON clinical.vitals;

ALTER TABLE clinical.vitals NO FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.vitals DISABLE ROW LEVEL SECURITY;
