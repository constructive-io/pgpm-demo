-- Deploy schemas/lab_results to pg

CREATE SCHEMA lab_results;
GRANT USAGE ON SCHEMA lab_results TO authenticated;
