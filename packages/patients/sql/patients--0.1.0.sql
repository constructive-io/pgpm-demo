\echo Use "CREATE EXTENSION patients" to load this file. \quit
DO $EOFCODE$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END $EOFCODE$;

CREATE SCHEMA app;

GRANT USAGE ON SCHEMA app TO authenticated;

CREATE FUNCTION app.current_user_id() RETURNS uuid LANGUAGE sql STABLE AS $EOFCODE$
    SELECT nullif(current_setting('app.user_id', true), '')::uuid
  $EOFCODE$;

GRANT EXECUTE ON FUNCTION app.current_user_id() TO authenticated;

CREATE FUNCTION app.current_role() RETURNS text LANGUAGE sql STABLE AS $EOFCODE$
    SELECT nullif(current_setting('app.role', true), '')
  $EOFCODE$;

GRANT EXECUTE ON FUNCTION app."current_role"() TO authenticated;

CREATE FUNCTION app.is_clinician_or_admin() RETURNS boolean LANGUAGE sql STABLE AS $EOFCODE$
    SELECT app.current_role() IN ('clinician', 'admin')
  $EOFCODE$;

GRANT EXECUTE ON FUNCTION app.is_clinician_or_admin() TO authenticated;

CREATE SCHEMA patients;

GRANT USAGE ON SCHEMA patients TO authenticated;

CREATE TABLE patients.patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  date_of_birth date NOT NULL,
  sex text,
  mrn text UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON patients.patients TO authenticated;

CREATE TABLE patients.patient_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('emergency', 'guardian', 'primary', 'next_of_kin')),
  name text NOT NULL,
  phone text,
  email text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX patient_contacts_patient_id_idx ON patients.patient_contacts (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON patients.patient_contacts TO authenticated;

ALTER TABLE patients.patients 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE patients.patients 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY patients_select
  ON patients.patients
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR id = app.current_user_id()
  );

CREATE POLICY patients_insert
  ON patients.patients
  AS PERMISSIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    app.is_clinician_or_admin()
  );

CREATE POLICY patients_update
  ON patients.patients
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR id = app.current_user_id()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
      OR id = app.current_user_id()
  );

CREATE POLICY patients_delete
  ON patients.patients
  AS PERMISSIVE
  FOR DELETE
  TO authenticated
  USING (
    app.current_role() = 'admin'
  );

ALTER TABLE patients.patient_contacts 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE patients.patient_contacts 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY patient_contacts_select
  ON patients.patient_contacts
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY patient_contacts_modify
  ON patients.patient_contacts
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );