-- Deploy schemas/lab_orders to pg

CREATE SCHEMA lab_orders;
GRANT USAGE ON SCHEMA lab_orders TO authenticated;
