-- Revert schemas/patients/policies/patient_contacts_rls from pg

DROP POLICY patient_contacts_modify ON patients.patient_contacts;
DROP POLICY patient_contacts_select ON patients.patient_contacts;

ALTER TABLE patients.patient_contacts NO FORCE ROW LEVEL SECURITY;
ALTER TABLE patients.patient_contacts DISABLE ROW LEVEL SECURITY;
