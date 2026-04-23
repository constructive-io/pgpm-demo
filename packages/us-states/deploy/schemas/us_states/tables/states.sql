-- Deploy schemas/us_states/tables/states to pg
-- requires: schemas/us_states

CREATE TABLE us_states.states (
  code char(2) PRIMARY KEY,
  name text NOT NULL UNIQUE,
  capital text NOT NULL,
  region text NOT NULL,
  is_state boolean NOT NULL DEFAULT true,
  admitted_on date
);

CREATE INDEX states_region_idx ON us_states.states (region);
