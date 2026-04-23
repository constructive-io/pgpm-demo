-- Revert schemas/scheduling/policies/encounters_rls from pg

DROP POLICY encounters_modify ON scheduling.encounters;
DROP POLICY encounters_select ON scheduling.encounters;

ALTER TABLE scheduling.encounters NO FORCE ROW LEVEL SECURITY;
ALTER TABLE scheduling.encounters DISABLE ROW LEVEL SECURITY;
