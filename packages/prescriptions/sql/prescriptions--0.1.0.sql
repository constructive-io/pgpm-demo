\echo Use "CREATE EXTENSION prescriptions" to load this file. \quit
CREATE SCHEMA prescriptions;

GRANT USAGE ON SCHEMA prescriptions TO authenticated;

CREATE TABLE prescriptions.prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters (id)
    ON DELETE SET NULL,
  medication_id uuid NOT NULL REFERENCES medications.medications (id),
  prescribing_clinician_id uuid,
  dosage text NOT NULL,
  route text NOT NULL,
  frequency text NOT NULL,
  quantity int NOT NULL CHECK (quantity > 0),
  refills int NOT NULL DEFAULT 0 CHECK (refills >= 0),
  instructions text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled', 'expired')),
  prescribed_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX prescriptions_patient_id_idx ON prescriptions.prescriptions (patient_id);

CREATE INDEX prescriptions_medication_id_idx ON prescriptions.prescriptions (medication_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON prescriptions.prescriptions TO authenticated;

ALTER TABLE prescriptions.prescriptions 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE prescriptions.prescriptions 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY prescriptions_select
  ON prescriptions.prescriptions
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY prescriptions_modify
  ON prescriptions.prescriptions
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    app.is_clinician_or_admin()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
  );