-- Deploy schemas/clinical/tables/conditions to pg
-- requires: schemas/clinical

CREATE TABLE clinical.conditions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters(id) ON DELETE SET NULL,
  icd10_code text,
  description text NOT NULL,
  onset_date date,
  resolved_date date,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'resolved', 'inactive', 'suspected')),
  severity text CHECK (severity IN ('mild', 'moderate', 'severe')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX conditions_patient_id_idx ON clinical.conditions (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON clinical.conditions TO authenticated;
