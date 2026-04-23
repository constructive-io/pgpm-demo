-- Deploy schemas/scheduling/tables/appointments to pg
-- requires: schemas/scheduling

CREATE TABLE scheduling.appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  clinician_id uuid,
  scheduled_at timestamptz NOT NULL,
  duration_minutes int NOT NULL DEFAULT 30 CHECK (duration_minutes > 0),
  reason text,
  status text NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'checked_in', 'completed', 'cancelled', 'no_show')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX appointments_patient_id_idx ON scheduling.appointments (patient_id);
CREATE INDEX appointments_scheduled_at_idx ON scheduling.appointments (scheduled_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON scheduling.appointments TO authenticated;
