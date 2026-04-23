-- Revert schemas/clinical/policies/conditions_rls from pg

DROP POLICY conditions_modify ON clinical.conditions;
DROP POLICY conditions_select ON clinical.conditions;

ALTER TABLE clinical.conditions NO FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.conditions DISABLE ROW LEVEL SECURITY;
