-- Deploy schemas/app to pg

CREATE SCHEMA app;
GRANT USAGE ON SCHEMA app TO authenticated;
