-- Deploy schemas/patients/tables/patients to pg
-- requires: schemas/patients

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
