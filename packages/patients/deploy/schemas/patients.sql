-- Deploy schemas/patients to pg

CREATE SCHEMA patients;
GRANT USAGE ON SCHEMA patients TO authenticated;
