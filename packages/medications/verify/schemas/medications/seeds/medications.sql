-- Verify schemas/medications/seeds/medications on pg

DO $$
BEGIN
  ASSERT (SELECT count(*) FROM medications.medications) >= 10,
    'Expected at least 10 rows in medications.medications';
END $$;
