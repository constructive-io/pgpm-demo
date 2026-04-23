-- Deploy schemas/clinical/tables/allergies to pg
-- requires: schemas/clinical

CREATE TABLE clinical.allergies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters(id) ON DELETE SET NULL,
  allergen text NOT NULL,
  reaction text,
  severity text NOT NULL DEFAULT 'moderate'
    CHECK (severity IN ('mild', 'moderate', 'severe', 'life_threatening')),
  recorded_on date NOT NULL DEFAULT current_date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX allergies_patient_id_idx ON clinical.allergies (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON clinical.allergies TO authenticated;
