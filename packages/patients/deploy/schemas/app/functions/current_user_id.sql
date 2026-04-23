-- Deploy schemas/app/functions/current_user_id to pg
-- requires: schemas/app

CREATE FUNCTION app.current_user_id() RETURNS uuid
  LANGUAGE sql STABLE AS $$
    SELECT nullif(current_setting('app.user_id', true), '')::uuid
  $$;

GRANT EXECUTE ON FUNCTION app.current_user_id() TO authenticated;
