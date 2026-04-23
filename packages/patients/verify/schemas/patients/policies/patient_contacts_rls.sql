-- Verify schemas/patients/policies/patient_contacts_rls on pg

DO $$
BEGIN
  ASSERT (SELECT relrowsecurity FROM pg_class
          WHERE oid = 'patients.patient_contacts'::regclass),
    'RLS not enabled on patients.patient_contacts';
END $$;
