\echo Use "CREATE EXTENSION documents" to load this file. \quit
CREATE SCHEMA documents;

GRANT USAGE ON SCHEMA documents TO authenticated;

CREATE TABLE documents.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients (id)
    ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters (id)
    ON DELETE SET NULL,
  uploaded_by uuid,
  kind text NOT NULL CHECK (kind IN ('clinical_note', 'imaging', 'consent', 'referral', 'discharge_summary', 'other')),
  title text NOT NULL,
  mime_type text,
  storage_url text,
  body text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX documents_patient_id_idx ON documents.documents (patient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON documents.documents TO authenticated;

ALTER TABLE documents.documents 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE documents.documents 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY documents_select
  ON documents.documents
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR patient_id = app.current_user_id()
  );

CREATE POLICY documents_modify
  ON documents.documents
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    app.is_clinician_or_admin()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
  );