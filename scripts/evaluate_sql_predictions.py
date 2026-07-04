from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REFERENCE_PATH = PROJECT_ROOT / "data" / "test.jsonl"
DEFAULT_DB_PATH = PROJECT_ROOT / "data" / "shopify_sample.db"
DEFAULT_FAILURES_PATH = PROJECT_ROOT / "data" / "evaluation_failures.jsonl"

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from data.init_db import initialize_database  # noqa: E402


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Evaluate predicted SQL against a reference JSONL split using exact match, "
            "normalization-aware match, execution success, and result equivalence."
        )
    )
    parser.add_argument(
        "--reference-path",
        type=Path,
        default=DEFAULT_REFERENCE_PATH,
        help=f"Reference JSONL file. Defaults to {DEFAULT_REFERENCE_PATH}.",
    )
    parser.add_argument(
        "--predictions-path",
        type=Path,
        required=True,
        help="Predictions file. Each line can be raw SQL or JSON/JSONL with a prediction field.",
    )
    parser.add_argument(
        "--db-path",
        type=Path,
        default=DEFAULT_DB_PATH,
        help=f"SQLite database path. Defaults to {DEFAULT_DB_PATH}.",
    )
    parser.add_argument(
        "--refresh-db",
        action="store_true",
        help="Recreate the SQLite database from schema and seed data before evaluation.",
    )
    parser.add_argument(
        "--failures-path",
        type=Path,
        default=DEFAULT_FAILURES_PATH,
        help=f"Where to write per-example failures. Defaults to {DEFAULT_FAILURES_PATH}.",
    )
    parser.add_argument(
        "--skip-failure-log",
        action="store_true",
        help="Skip writing the per-example failure JSONL report.",
    )
    return parser.parse_args()


def load_jsonl(path: Path) -> list[str]:
    return [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def extract_message(example: dict[str, Any], role: str) -> str:
    messages = example.get("messages", [])
    if not isinstance(messages, list):
        raise ValueError("Example messages must be a list")

    for message in messages:
        if isinstance(message, dict) and message.get("role") == role:
            return str(message.get("content", ""))

    raise ValueError(f"Missing {role!r} message")


def parse_reference_line(raw_line: str) -> dict[str, str]:
    example = json.loads(raw_line)
    return {
        "prompt": extract_message(example, "user"),
        "reference_sql": extract_message(example, "assistant").strip(),
    }


def parse_prediction_line(raw_line: str) -> str:
    stripped = raw_line.strip()
    if not stripped:
        raise ValueError("Prediction line is empty")

    try:
        payload = json.loads(stripped)
    except json.JSONDecodeError:
        return stripped

    if isinstance(payload, str):
        return payload.strip()

    if isinstance(payload, dict):
        for key in ("prediction_sql", "predicted_sql", "assistant_sql", "sql", "completion"):
            value = payload.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()

        if "messages" in payload:
            return extract_message(payload, "assistant").strip()

    raise ValueError("Unsupported prediction line format")


def normalize_sql(sql: str) -> str:
    normalized = re.sub(r"\s+", " ", sql.strip())
    normalized = normalized.rstrip(";")
    return normalized.lower()


def statement_type(sql: str) -> str:
    match = re.match(r"^\s*([a-zA-Z]+)", sql)
    if not match:
        return "UNKNOWN"

    statement = match.group(1).upper()
    if statement == "WITH":
        return "SELECT"
    return statement


def classify_statement_group(sql: str) -> str:
    statement = statement_type(sql)
    if statement == "SELECT":
        return "read"
    if statement in {"INSERT", "UPDATE", "DELETE"}:
        return "write"
    return "other"


def snapshot_database(connection: sqlite3.Connection) -> str:
    return "\n".join(connection.iterdump())


def execute_sql(sql: str, seed_connection: sqlite3.Connection) -> dict[str, Any]:
    connection = sqlite3.connect(":memory:")
    seed_connection.backup(connection)

    try:
        cursor = connection.execute(sql)
        if cursor.description is not None:
            outcome = {
                "success": True,
                "statement_type": statement_type(sql),
                "columns": [column[0] for column in cursor.description],
                "rows": cursor.fetchall(),
            }
        else:
            outcome = {
                "success": True,
                "statement_type": statement_type(sql),
                "changes": connection.execute("SELECT changes();").fetchone()[0],
                "snapshot": snapshot_database(connection),
            }
    except Exception as exc:  # noqa: BLE001
        outcome = {
            "success": False,
            "statement_type": statement_type(sql),
            "error": f"{type(exc).__name__}: {exc}",
        }
    finally:
        connection.close()

    return outcome


def outcomes_match(reference: dict[str, Any], prediction: dict[str, Any]) -> bool:
    if not reference["success"] or not prediction["success"]:
        return False

    if reference["statement_type"] != prediction["statement_type"]:
        return False

    if reference["statement_type"] == "SELECT":
        return (
            reference.get("columns") == prediction.get("columns")
            and reference.get("rows") == prediction.get("rows")
        )

    return (
        reference.get("changes") == prediction.get("changes")
        and reference.get("snapshot") == prediction.get("snapshot")
    )


def format_metric(numerator: int, denominator: int) -> str:
    if denominator == 0:
        return "0/0 (0.00%)"
    percentage = numerator / denominator * 100
    return f"{numerator}/{denominator} ({percentage:.2f}%)"


def write_failures(path: Path, failures: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    serialized = "\n".join(json.dumps(failure, ensure_ascii=True) for failure in failures)
    if serialized:
        serialized += "\n"
    path.write_text(serialized, encoding="utf-8")


def main() -> None:
    args = parse_args()

    if args.refresh_db or not args.db_path.exists():
        initialize_database(args.db_path, reset=True)

    reference_lines = load_jsonl(args.reference_path)
    prediction_lines = load_jsonl(args.predictions_path)

    if len(reference_lines) != len(prediction_lines):
        raise ValueError(
            f"Reference/prediction length mismatch: {len(reference_lines)} references vs "
            f"{len(prediction_lines)} predictions"
        )

    overall_metrics = {
        "exact_match": 0,
        "normalized_match": 0,
        "prediction_executable": 0,
        "result_match": 0,
    }
    per_group_metrics: dict[str, dict[str, int]] = defaultdict(
        lambda: {"count": 0, "exact_match": 0, "normalized_match": 0, "prediction_executable": 0, "result_match": 0}
    )
    failures: list[dict[str, Any]] = []

    with sqlite3.connect(args.db_path) as seed_connection:
        for index, (reference_line, prediction_line) in enumerate(
            zip(reference_lines, prediction_lines, strict=True), start=1
        ):
            reference = parse_reference_line(reference_line)
            prediction_sql = parse_prediction_line(prediction_line)

            statement_group = classify_statement_group(reference["reference_sql"])
            per_group_metrics[statement_group]["count"] += 1

            exact_match = reference["reference_sql"].strip() == prediction_sql.strip()
            normalized_match = normalize_sql(reference["reference_sql"]) == normalize_sql(prediction_sql)

            reference_outcome = execute_sql(reference["reference_sql"], seed_connection)
            prediction_outcome = execute_sql(prediction_sql, seed_connection)
            prediction_executable = prediction_outcome["success"]
            result_match = outcomes_match(reference_outcome, prediction_outcome)

            overall_metrics["exact_match"] += int(exact_match)
            overall_metrics["normalized_match"] += int(normalized_match)
            overall_metrics["prediction_executable"] += int(prediction_executable)
            overall_metrics["result_match"] += int(result_match)

            per_group_metrics[statement_group]["exact_match"] += int(exact_match)
            per_group_metrics[statement_group]["normalized_match"] += int(normalized_match)
            per_group_metrics[statement_group]["prediction_executable"] += int(prediction_executable)
            per_group_metrics[statement_group]["result_match"] += int(result_match)

            if not result_match:
                failures.append(
                    {
                        "line_number": index,
                        "prompt": reference["prompt"],
                        "statement_group": statement_group,
                        "reference_sql": reference["reference_sql"],
                        "prediction_sql": prediction_sql,
                        "exact_match": exact_match,
                        "normalized_match": normalized_match,
                        "prediction_executable": prediction_executable,
                        "reference_error": reference_outcome.get("error"),
                        "prediction_error": prediction_outcome.get("error"),
                    }
                )

    total_examples = len(reference_lines)
    print(f"Examples evaluated: {total_examples}")
    print("Overall metrics:")
    for metric_name, value in overall_metrics.items():
        print(f"- {metric_name}: {format_metric(value, total_examples)}")

    print("Metrics by statement group:")
    for group_name in sorted(per_group_metrics):
        group_total = per_group_metrics[group_name]["count"]
        print(f"- {group_name}:")
        for metric_name in ("exact_match", "normalized_match", "prediction_executable", "result_match"):
            print(f"  - {metric_name}: {format_metric(per_group_metrics[group_name][metric_name], group_total)}")

    if args.skip_failure_log:
        print("Failure log skipped.")
    else:
        write_failures(args.failures_path, failures)
        print(f"Failure log written to {args.failures_path}")


if __name__ == "__main__":
    main()
