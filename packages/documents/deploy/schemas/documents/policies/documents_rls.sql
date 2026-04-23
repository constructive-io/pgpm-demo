-- Deploy schemas/documents/policies/documents_rls to pg
-- requires: schemas/documents/tables/documents

ALTER TABLE documents.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents.documents FORCE ROW LEVEL SECURITY;

CREATE POLICY documents_select ON documents.documents
  FOR SELECT TO authenticated
  USING (
    app.is_clinician_or_admin()
    OR patient_id = app.current_user_id()
  );

CREATE POLICY documents_modify ON documents.documents
  FOR ALL TO authenticated
  USING (app.is_clinician_or_admin())
  WITH CHECK (app.is_clinician_or_admin());
