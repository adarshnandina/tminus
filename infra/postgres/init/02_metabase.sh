#!/usr/bin/env bash
# Runs ONCE on an empty volume. Metabase's own application database
# (users, questions, dashboards), isolated from the warehouse.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
  CREATE ROLE metabase LOGIN PASSWORD '${METABASE_DB_PASSWORD}';
  CREATE DATABASE metabase OWNER metabase;
  REVOKE CONNECT ON DATABASE metabase FROM PUBLIC;
EOSQL
