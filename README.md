# T-Minus

Data platform for **Ostwind Orbital**, a fictional European launch startup.
It brings engineering, manufacturing, business and launch-market data into one
PostgreSQL warehouse and turns it into trusted KPIs.

**Stack:** dlt · PostgreSQL · dbt · Dagster · Metabase · Power BI · Docker · GitHub Actions

> Status: Stage 0 (foundations) in progress.

## Quickstart

    cp .env.example .env        # then set real passwords
    docker compose up -d --wait
    uv sync
    uv run pre-commit install

## Repository layout

| Path | Purpose |
|---|---|
| `src/tminus/simulator` | Factory database simulator |
| `src/tminus/ingestion` | dlt pipelines |
| `src/tminus/orchestration` | Dagster definitions |
| `transform/` | dbt project |
| `infra/` | Database init scripts |
| `docs/` | ADRs and runbooks |
