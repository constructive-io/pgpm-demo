\echo Use "CREATE EXTENSION lab-results" to load this file. \quit
CREATE SCHEMA lab_results;

GRANT USAGE ON SCHEMA lab_results TO authenticated;

CREATE TABLE lab_results.lab_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lab_order_id uuid NOT NULL REFERENCES lab_orders.lab_orders (id)
    ON DELETE CASCADE,
  analyte text NOT NULL,
  value_numeric numeric,
  value_text text,
  unit text,
  reference_low numeric,
  reference_high numeric,
  flag text CHECK (flag IN ('normal', 'low', 'high', 'critical_low', 'critical_high', 'abnormal')),
  resulted_at timestamptz NOT NULL DEFAULT now(),
  verified_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX lab_results_order_id_idx ON lab_results.lab_results (lab_order_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON lab_results.lab_results TO authenticated;

ALTER TABLE lab_results.lab_results 
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE lab_results.lab_results 
  FORCE ROW LEVEL SECURITY;

CREATE POLICY lab_results_select
  ON lab_results.lab_results
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    app.is_clinician_or_admin()
      OR EXISTS (SELECT 1
    FROM lab_orders.lab_orders AS o
    WHERE
      (o.id = lab_order_id
      AND o.patient_id = app.current_user_id()))
  );

CREATE POLICY lab_results_modify
  ON lab_results.lab_results
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    app.is_clinician_or_admin()
  )
  WITH CHECK (
    app.is_clinician_or_admin()
  );