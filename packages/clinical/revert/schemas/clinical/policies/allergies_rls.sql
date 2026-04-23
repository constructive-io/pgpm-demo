-- Revert schemas/clinical/policies/allergies_rls from pg

DROP POLICY allergies_modify ON clinical.allergies;
DROP POLICY allergies_select ON clinical.allergies;

ALTER TABLE clinical.allergies NO FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.allergies DISABLE ROW LEVEL SECURITY;
