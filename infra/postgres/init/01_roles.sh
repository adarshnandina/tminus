#!/usr/bin/env bash
# Runs ONCE, on first start with an empty data volume.
# Creates one least-privilege login per tool.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
  -- Nobody may connect unless explicitly allowed
  REVOKE CONNECT ON DATABASE ${POSTGRES_DB} FROM PUBLIC;

  -- loader (dlt): creates raw schemas and writes raw data
  CREATE ROLE loader LOGIN PASSWORD '${LOADER_PASSWORD}';
  GRANT CONNECT, CREATE ON DATABASE ${POSTGRES_DB} TO loader;

  -- transformer (dbt): reads raw data, builds staging/marts schemas
  CREATE ROLE transformer LOGIN PASSWORD '${TRANSFORMER_PASSWORD}';
  GRANT CONNECT, CREATE ON DATABASE ${POSTGRES_DB} TO transformer;
  -- Anything loader creates in future is automatically readable by transformer
  ALTER DEFAULT PRIVILEGES FOR ROLE loader GRANT USAGE ON SCHEMAS TO transformer;
  ALTER DEFAULT PRIVILEGES FOR ROLE loader GRANT SELECT ON TABLES TO transformer;

  -- reporter (BI tools): connect only; dbt grants read access to marts in Stage 3
  CREATE ROLE reporter LOGIN PASSWORD '${REPORTER_PASSWORD}';
  GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO reporter;
EOSQL
