-- Deploy schemas/documents to pg

CREATE SCHEMA documents;
GRANT USAGE ON SCHEMA documents TO authenticated;
