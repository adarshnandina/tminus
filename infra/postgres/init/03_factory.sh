#!/usr/bin/env bash
# Factory (MES) source database: simulates Ostwind Orbital's manufacturing system.
# Owned by factory_app (the simulator); loader (dlt) gets read-only access.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
  CREATE ROLE factory_app LOGIN PASSWORD '${FACTORY_DB_PASSWORD}';
  CREATE DATABASE factory OWNER factory_app;
  REVOKE CONNECT ON DATABASE factory FROM PUBLIC;
  GRANT CONNECT ON DATABASE factory TO loader;
EOSQL

# Schema grants only apply inside the database you are connected to,
# so this part connects to "factory".
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname factory <<EOSQL
  CREATE SCHEMA mes AUTHORIZATION factory_app;
  GRANT USAGE ON SCHEMA mes TO loader;
  ALTER DEFAULT PRIVILEGES FOR ROLE factory_app IN SCHEMA mes GRANT SELECT ON TABLES TO loader;
EOSQL
