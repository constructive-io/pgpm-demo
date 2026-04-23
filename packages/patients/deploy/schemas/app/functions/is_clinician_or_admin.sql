-- Deploy schemas/app/functions/is_clinician_or_admin to pg
-- requires: schemas/app/functions/current_role

CREATE FUNCTION app.is_clinician_or_admin() RETURNS boolean
  LANGUAGE sql STABLE AS $$
    SELECT app.current_role() IN ('clinician', 'admin')
  $$;

GRANT EXECUTE ON FUNCTION app.is_clinician_or_admin() TO authenticated;
