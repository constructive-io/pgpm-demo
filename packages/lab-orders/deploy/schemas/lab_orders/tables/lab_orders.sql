-- Deploy schemas/lab_orders/tables/lab_orders to pg
-- requires: schemas/lab_orders

CREATE TABLE lab_orders.lab_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients.patients(id) ON DELETE CASCADE,
  encounter_id uuid REFERENCES scheduling.encounters(id) ON DELETE SET NULL,
  ordering_clinician_id uuid,
  test_code text NOT NULL,
  test_name text NOT NULL,
  priority text NOT NULL DEFAULT 'routine'
    CHECK (priority IN ('stat', 'asap', 'routine')),
  status text NOT NULL DEFAULT 'ordered'
    CHECK (status IN ('ordered', 'collected', 'in_lab', 'resulted', 'cancelled')),
  ordered_at timestamptz NOT NULL DEFAULT now(),
  collected_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX lab_orders_patient_id_idx ON lab_orders.lab_orders (patient_id);
CREATE INDEX lab_orders_status_idx ON lab_orders.lab_orders (status);

GRANT SELECT, INSERT, UPDATE, DELETE ON lab_orders.lab_orders TO authenticated;
