-- Deploy schemas/scheduling to pg

CREATE SCHEMA scheduling;
GRANT USAGE ON SCHEMA scheduling TO authenticated;
