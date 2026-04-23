-- Deploy schemas/documents/tables/documents to pg
-- requires: schemas/documents

CREATE TABLE documents.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters(id) ON DELETE SET NULL,
  uploaded_by uuid,
  kind text NOT NULL
    CHECK (kind IN ('clinical_note', 'imaging', 'consent', 'referral', 'discharge_summary', 'other')),
  title text NOT NULL,
  mime_type text,
  storage_url text,
  body text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX documents_patient_id_idx ON documents.documents (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON documents.documents TO authenticated;
