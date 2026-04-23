\echo Use "CREATE EXTENSION clinical" to load this file. \quit
CREATE SCHEMA clinical;

GRANT USAGE ON SCHEMA clinical TO authenticated;

CREATE TABLE clinical.conditions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters (id)
    ON DELETE SET NULL,
  icd10_code text,
  description text NOT NULL,
  onset_date date,
  resolved_date date,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'inactive', 'suspected')),
  severity text CHECK (severity IN ('mild', 'moderate', 'severe')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX conditions_patient_id_idx ON clinical.conditions (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON clinical.conditions TO authenticated;

CREATE TABLE clinical.allergies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters (id)
    ON DELETE SET NULL,
  allergen text NOT NULL,
  reaction text,
  severity text NOT NULL DEFAULT 'moderate' CHECK (severity IN ('mild', 'moderate', 'severe', 'life_threatening')),
  recorded_on date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX allergies_patient_id_idx ON clinical.allergies (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON clinical.allergies TO authenticated;

CREATE TABLE clinical.vitals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters (id)
    ON DELETE SET NULL,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  heart_rate_bpm int CHECK (
    heart_rate_bpm > 0
      AND heart_rate_bpm < 350
  ),
  systolic_bp int CHECK (
    systolic_bp > 0
      AND systolic_bp < 300
  ),
  diastolic_bp int CHECK (
    diastolic_bp > 0
      AND diastolic_bp < 200
  ),
  respiratory_rate int CHECK (
    respiratory_rate > 0
      AND respiratory_rate < 100
  ),
  temperature_c numeric(4, 1) CHECK (
    temperature_c > 25
      AND temperature_c < 50
  ),
  oxygen_saturation int CHECK (oxygen_saturation BETWEEN 0 AND 100),
  weight_kg numeric(6, 2) CHECK (weight_kg > 0),
  height_cm numeric(5, 1) CHECK (height_cm > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX vitals_patient_id_idx ON clinical.vitals (patient_id, recorded_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON clinical.vitals TO authenticated;

ALTER TABLE clinical.conditions 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinical.conditions 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY conditions_select
  ON clinical.conditions
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY conditions_modify
  ON clinical.conditions
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    app.is_clinician_or_admin()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
  );

ALTER TABLE clinical.allergies 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinical.allergies 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY allergies_select
  ON clinical.allergies
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY allergies_modify
  ON clinical.allergies
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

ALTER TABLE clinical.vitals 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE clinical.vitals 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY vitals_select
  ON clinical.vitals
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY vitals_modify
  ON clinical.vitals
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    app.is_clinician_or_admin()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
  );