-- Deploy schemas/patients/tables/patient_contacts to pg
-- requires: schemas/patients/tables/patients

CREATE TABLE patients.patient_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('emergency', 'guardian', 'primary', 'next_of_kin')),
  name text NOT NULL,
  phone text,
  email text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX patient_contacts_patient_id_idx ON patients.patient_contacts (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON patients.patient_contacts TO authenticated;
