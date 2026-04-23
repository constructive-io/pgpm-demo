\echo Use "CREATE EXTENSION scheduling" to load this file. \quit
CREATE SCHEMA scheduling;

GRANT USAGE ON SCHEMA scheduling TO authenticated;

CREATE TABLE scheduling.appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  clinician_id uuid,
  scheduled_at timestamptz NOT NULL,
  duration_minutes int NOT NULL DEFAULT 30 CHECK (duration_minutes > 0),
  reason text,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'checked_in', 'completed', 'cancelled', 'no_show')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX appointments_patient_id_idx ON scheduling.appointments (patient_id);

CREATE INDEX appointments_scheduled_at_idx ON scheduling.appointments (scheduled_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON scheduling.appointments TO authenticated;

CREATE TABLE scheduling.encounters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid REFERENCES scheduling.appointments (id)
    ON DELETE SET NULL,
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  clinician_id uuid,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  encounter_type text NOT NULL DEFAULT 'office_visit' CHECK (encounter_type IN ('office_visit', 'telemedicine', 'emergency', 'inpatient', 'home_visit')),
  chief_complaint text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX encounters_patient_id_idx ON scheduling.encounters (patient_id);

CREATE INDEX encounters_appointment_id_idx ON scheduling.encounters (appointment_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON scheduling.encounters TO authenticated;

ALTER TABLE scheduling.appointments 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE scheduling.appointments 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY appointments_select
  ON scheduling.appointments
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY appointments_modify
  ON scheduling.appointments
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

ALTER TABLE scheduling.encounters 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE scheduling.encounters 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY encounters_select
  ON scheduling.encounters
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY encounters_modify
  ON scheduling.encounters
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    app.is_clinician_or_admin()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
  );