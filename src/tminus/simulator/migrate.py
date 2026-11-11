"""Apply versioned SQL migrations to the factory (MES) database.

Each file in migrations/ is applied once, in filename order, inside its own
transaction. Applied versions are recorded in mes.schema_migrations.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

import psycopg

log = logging.getLogger(__name__)

MIGRATIONS_DIR = Path(__file__).parent / "migrations"


def get_connection() -> psycopg.Connection:
    return psycopg.connect(
        host=os.environ.get("POSTGRES_HOST", "localhost"),
        port=int(os.environ.get("POSTGRES_PORT", "5432")),
        dbname="factory",
        user="factory_app",
        password=os.environ["FACTORY_DB_PASSWORD"],
    )


def migrate() -> None:
    with get_connection() as conn:
        conn.execute(
            """
            create table if not exists mes.schema_migrations (
                version    text primary key,
                applied_at timestamptz not null default now()
            )
            """
        )
        applied = {row[0] for row in conn.execute("select version from mes.schema_migrations")}
        conn.commit()

        for path in sorted(MIGRATIONS_DIR.glob("*.sql")):
            version = path.stem
            if version in applied:
                log.info("skip   %s (already applied)", version)
                continue
            # All-or-nothing: if the SQL fails, the version is not recorded either
            with conn.transaction():
                conn.execute(path.read_text())
                conn.execute("insert into mes.schema_migrations (version) values (%s)", (version,))
            log.info("apply  %s", version)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    migrate()
