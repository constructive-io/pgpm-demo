-- Deploy schemas/clinical to pg

CREATE SCHEMA clinical;
GRANT USAGE ON SCHEMA clinical TO authenticated;
