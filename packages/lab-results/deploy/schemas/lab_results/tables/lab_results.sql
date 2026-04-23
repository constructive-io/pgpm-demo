-- Deploy schemas/lab_results/tables/lab_results to pg
-- requires: schemas/lab_results

CREATE TABLE lab_results.lab_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lab_order_id uuid NOT NULL REFERENCES lab_orders.lab_orders(id) ON DELETE CASCADE,
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
