-- Deploy schemas/clinical/tables/vitals to pg
-- requires: schemas/clinical

CREATE TABLE clinical.vitals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters(id) ON DELETE SET NULL,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  heart_rate_bpm int CHECK (heart_rate_bpm > 0 AND heart_rate_bpm < 350),
  systolic_bp int CHECK (systolic_bp > 0 AND systolic_bp < 300),
  diastolic_bp int CHECK (diastolic_bp > 0 AND diastolic_bp < 200),
  respiratory_rate int CHECK (respiratory_rate > 0 AND respiratory_rate < 100),
  temperature_c numeric(4,1) CHECK (temperature_c > 25 AND temperature_c < 50),
  oxygen_saturation int CHECK (oxygen_saturation BETWEEN 0 AND 100),
  weight_kg numeric(6,2) CHECK (weight_kg > 0),
  height_cm numeric(5,1) CHECK (height_cm > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX vitals_patient_id_idx ON clinical.vitals (patient_id, recorded_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON clinical.vitals TO authenticated;
