-- Deploy schemas/medications/seeds/medications to pg
-- requires: schemas/medications/tables/medications

INSERT INTO medications.medications (rxnorm_cui, generic_name, brand_name, strength, form, route, is_controlled, schedule) VALUES
  ('197361',  'amoxicillin',       'Amoxil',      '500 mg',    'capsule', 'oral',  false, NULL),
  ('313782',  'acetaminophen',     'Tylenol',     '500 mg',    'tablet',  'oral',  false, NULL),
  ('197805',  'ibuprofen',         'Advil',       '200 mg',    'tablet',  'oral',  false, NULL),
  ('310965',  'lisinopril',        'Prinivil',    '10 mg',     'tablet',  'oral',  false, NULL),
  ('860975',  'metformin',         'Glucophage',  '500 mg',    'tablet',  'oral',  false, NULL),
  ('617314',  'atorvastatin',      'Lipitor',     '20 mg',     'tablet',  'oral',  false, NULL),
  ('314231',  'omeprazole',        'Prilosec',    '20 mg',     'capsule', 'oral',  false, NULL),
  ('313850',  'albuterol',         'Ventolin',    '90 mcg',    'inhaler', 'inhalation', false, NULL),
  ('849574',  'oxycodone',         'OxyContin',   '5 mg',      'tablet',  'oral',  true,  'II'),
  ('856987',  'alprazolam',        'Xanax',       '0.5 mg',    'tablet',  'oral',  true,  'IV');
