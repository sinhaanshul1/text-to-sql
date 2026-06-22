from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent
DEFAULT_DB_PATH = DATA_DIR / "shopify_sample.db"
SCHEMA_PATH = DATA_DIR / "schema.sql"
SEED_DATA_PATH = DATA_DIR / "seed_data.sql"


def run_sql_file(connection: sqlite3.Connection, sql_path: Path) -> None:
    if not sql_path.exists():
        raise FileNotFoundError(f"Missing SQL file: {sql_path}")

    connection.executescript(sql_path.read_text(encoding="utf-8"))


def initialize_database(db_path: Path, reset: bool = False) -> None:
    if reset and db_path.exists():
        db_path.unlink()

    db_path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(db_path) as connection:
        connection.execute("PRAGMA foreign_keys = ON;")
        run_sql_file(connection, SCHEMA_PATH)
        run_sql_file(connection, SEED_DATA_PATH)
        connection.commit()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Initialize the local Shopify-style SQLite sample database."
    )
    parser.add_argument(
        "--db-path",
        type=Path,
        default=DEFAULT_DB_PATH,
        help=f"SQLite database path. Defaults to {DEFAULT_DB_PATH}.",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Delete the existing database file before recreating it.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    initialize_database(args.db_path, reset=args.reset)
    print(f"Initialized database at {args.db_path}")


if __name__ == "__main__":
    main()
