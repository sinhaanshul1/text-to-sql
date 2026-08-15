from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATASET_PATH = PROJECT_ROOT / "data" / "training_corpus.jsonl"
DEFAULT_DB_PATH = PROJECT_ROOT / "data" / "shopify_sample.db"
ALLOWED_MESSAGE_ROLES = ("system", "user", "assistant")
ALLOWED_STATEMENT_TYPES = {"SELECT", "INSERT", "UPDATE", "DELETE"}

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


def load_example(line_number: int, raw_line: str) -> dict[str, Any]:
    try:
        example = json.loads(raw_line)
    except json.JSONDecodeError as exc:
        raise ValueError(f"line {line_number}: invalid JSON: {exc.msg}") from exc

    if not isinstance(example, dict):
        raise ValueError(f"line {line_number}: example must be a JSON object")

    return example


def statement_type(sql: str) -> str:
    stripped_sql = sql.lstrip()
    if not stripped_sql:
        return "UNKNOWN"

    statement = stripped_sql.split(None, 1)[0].upper()
    if statement == "WITH":
        return "SELECT"
    return statement


def validate_messages(line_number: int, example: dict[str, Any]) -> tuple[str, str, str]:
    messages = example.get("messages")
    if not isinstance(messages, list):
        raise ValueError(f"line {line_number}: messages must be a list")

    if len(messages) != len(ALLOWED_MESSAGE_ROLES):
        raise ValueError(
            f"line {line_number}: expected exactly {len(ALLOWED_MESSAGE_ROLES)} messages "
            f"({', '.join(ALLOWED_MESSAGE_ROLES)}), found {len(messages)}"
        )

    extracted: dict[str, str] = {}
    for index, (message, expected_role) in enumerate(zip(messages, ALLOWED_MESSAGE_ROLES, strict=True), start=1):
        if not isinstance(message, dict):
            raise ValueError(f"line {line_number}: message {index} must be an object")

        role = message.get("role")
        if role != expected_role:
            raise ValueError(
                f"line {line_number}: message {index} must have role {expected_role!r}, found {role!r}"
            )

        content = message.get("content")
        if not isinstance(content, str) or not content.strip():
            raise ValueError(f"line {line_number}: {role!r} message content must be a non-empty string")

        extracted[role] = content.strip()

    return extracted["system"], extracted["user"], extracted["assistant"]


def validate_assistant_sql(connection: sqlite3.Connection, line_number: int, assistant_sql: str) -> None:
    statement = statement_type(assistant_sql)
    if statement not in ALLOWED_STATEMENT_TYPES:
        raise ValueError(
            f"line {line_number}: unsupported SQL statement type {statement!r}; "
            f"expected one of {sorted(ALLOWED_STATEMENT_TYPES)}"
        )

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


def validate_example(connection: sqlite3.Connection, line_number: int, raw_line: str) -> tuple[str, str]:
    example = load_example(line_number, raw_line)
    _system_prompt, user_prompt, assistant_sql = validate_messages(line_number, example)
    assistant_sql = assistant_sql.strip()

    if not assistant_sql:
        raise ValueError(f"line {line_number}: assistant SQL is empty")

    validate_assistant_sql(connection, line_number, assistant_sql)

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
