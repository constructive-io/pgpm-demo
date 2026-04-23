-- Revert schemas/lab_results/policies/lab_results_rls from pg

DROP POLICY lab_results_modify ON lab_results.lab_results;
DROP POLICY lab_results_select ON lab_results.lab_results;

ALTER TABLE lab_results.lab_results NO FORCE ROW LEVEL SECURITY;
ALTER TABLE lab_results.lab_results DISABLE ROW LEVEL SECURITY;
