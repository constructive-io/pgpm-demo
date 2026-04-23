-- Revert schemas/documents/policies/documents_rls from pg

DROP POLICY documents_modify ON documents.documents;
DROP POLICY documents_select ON documents.documents;

ALTER TABLE documents.documents NO FORCE ROW LEVEL SECURITY;
ALTER TABLE documents.documents DISABLE ROW LEVEL SECURITY;
