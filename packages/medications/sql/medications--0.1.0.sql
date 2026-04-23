\echo Use "CREATE EXTENSION medications" to load this file. \quit
CREATE SCHEMA medications;

GRANT USAGE ON SCHEMA medications TO PUBLIC;

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

CREATE INDEX medications_generic_name_idx ON medications.medications ((lower(generic_name)));

GRANT SELECT ON medications.medications TO PUBLIC;

INSERT INTO medications.medications (
  rxnorm_cui,
  generic_name,
  brand_name,
  strength,
  form,
  route,
  is_controlled,
  schedule
) VALUES
  ('197361', 'amoxicillin', 'Amoxil', '500 mg', 'capsule', 'oral', false, NULL),
  ('313782', 'acetaminophen', 'Tylenol', '500 mg', 'tablet', 'oral', false, NULL),
  ('197805', 'ibuprofen', 'Advil', '200 mg', 'tablet', 'oral', false, NULL),
  ('310965', 'lisinopril', 'Prinivil', '10 mg', 'tablet', 'oral', false, NULL),
  ('860975', 'metformin', 'Glucophage', '500 mg', 'tablet', 'oral', false, NULL),
  ('617314', 'atorvastatin', 'Lipitor', '20 mg', 'tablet', 'oral', false, NULL),
  ('314231', 'omeprazole', 'Prilosec', '20 mg', 'capsule', 'oral', false, NULL),
  ('313850', 'albuterol', 'Ventolin', '90 mcg', 'inhaler', 'inhalation', false, NULL),
  ('849574', 'oxycodone', 'OxyContin', '5 mg', 'tablet', 'oral', true, 'II'),
  ('856987', 'alprazolam', 'Xanax', '0.5 mg', 'tablet', 'oral', true, 'IV');