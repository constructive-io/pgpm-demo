-- Deploy schemas/app/functions/current_role to pg
-- requires: schemas/app

CREATE FUNCTION app.current_role() RETURNS text
  LANGUAGE sql STABLE AS $$
    SELECT nullif(current_setting('app.role', true), '')
  $$;

GRANT EXECUTE ON FUNCTION app.current_role() TO authenticated;
