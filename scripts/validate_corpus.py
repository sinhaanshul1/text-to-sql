from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATASET_PATH = PROJECT_ROOT / "data" / "training_corpus.jsonl"
DEFAULT_DB_PATH = PROJECT_ROOT / "data" / "shopify_sample.db"

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from data.init_db import initialize_database  # noqa: E402

# Parse args to teh script.
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate that every fine-tuning corpus example contains valid JSON and executable SQL."
    )
    parser.add_argument(
        "--dataset-path",
        type=Path,
        default=DEFAULT_DATASET_PATH,
        help=f"Path to the JSONL dataset. Defaults to {DEFAULT_DATASET_PATH}.",
    )
    parser.add_argument(
        "--db-path",
        type=Path,
        default=DEFAULT_DB_PATH,
        help=f"SQLite database path. Defaults to {DEFAULT_DB_PATH}.",
    )
    parser.add_argument(
        "--skip-reset",
        action="store_true",
        help="Skip recreating the SQLite database before validation.",
    )
    return parser.parse_args()


def extract_message(example: dict, role: str) -> str:
    for message in example.get("messages", []):
        if message.get("role") == role:
            return message.get("content", "")
    raise ValueError(f"Missing {role!r} message")


def validate_example(connection: sqlite3.Connection, line_number: int, raw_line: str) -> tuple[str, str]:
    example = json.loads(raw_line)
    user_prompt = extract_message(example, "user")
    assistant_sql = extract_message(example, "assistant").strip()

    if not assistant_sql:
        raise ValueError("Assistant SQL is empty")

    connection.execute("BEGIN;")
    try:
        cursor = connection.execute(assistant_sql)
        if cursor.description is not None:
            cursor.fetchall()
        else:
            connection.execute("SELECT changes();").fetchone()
    except Exception:
        connection.rollback()
        raise
    else:
        connection.rollback()

    return user_prompt, assistant_sql


def main() -> None:
    args = parse_args()

    if not args.skip_reset:
        initialize_database(args.db_path, reset=True)

    if not args.dataset_path.exists():
        raise FileNotFoundError(f"Missing dataset file: {args.dataset_path}")

    validated_examples = 0

    with sqlite3.connect(args.db_path) as connection:
        for line_number, raw_line in enumerate(
            args.dataset_path.read_text(encoding="utf-8").splitlines(), start=1
        ):
            if not raw_line.strip():
                continue

            user_prompt, _assistant_sql = validate_example(connection, line_number, raw_line)
            validated_examples += 1
            print(f"[ok] line {line_number}: {user_prompt}")

    print(f"Validated {validated_examples} examples from {args.dataset_path}")


if __name__ == "__main__":
    main()
