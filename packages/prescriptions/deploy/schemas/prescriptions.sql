-- Deploy schemas/prescriptions to pg

CREATE SCHEMA prescriptions;
GRANT USAGE ON SCHEMA prescriptions TO authenticated;
