-- Verify schemas/patients/tables/patient_contacts on pg

DO $$
BEGIN
  ASSERT (SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'patients' AND table_name = 'patient_contacts'
  )), 'Table patients.patient_contacts does not exist';
END $$;
