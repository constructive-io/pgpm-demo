-- Deploy schemas/medications/tables/medications to pg
-- requires: schemas/medications

CREATE TABLE medications.medications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rxnorm_cui text UNIQUE,
  generic_name text NOT NULL,
  brand_name text,
  strength text,
  form text,
  route text,
  is_controlled boolean NOT NULL DEFAULT false,
  schedule text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX medications_generic_name_idx ON medications.medications (lower(generic_name));

GRANT SELECT ON medications.medications TO PUBLIC;
