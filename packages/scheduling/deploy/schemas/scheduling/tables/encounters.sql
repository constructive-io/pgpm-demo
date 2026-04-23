-- Deploy schemas/scheduling/tables/encounters to pg
-- requires: schemas/scheduling/tables/appointments

CREATE TABLE scheduling.encounters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid REFERENCES scheduling.appointments(id) ON DELETE SET NULL,
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  clinician_id uuid,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  encounter_type text NOT NULL DEFAULT 'office_visit'
    CHECK (encounter_type IN ('office_visit', 'telemedicine', 'emergency', 'inpatient', 'home_visit')),
  chief_complaint text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX encounters_patient_id_idx ON scheduling.encounters (patient_id);
CREATE INDEX encounters_appointment_id_idx ON scheduling.encounters (appointment_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON scheduling.encounters TO authenticated;
