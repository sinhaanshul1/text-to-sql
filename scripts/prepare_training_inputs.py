from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT_DIR = PROJECT_ROOT / "data"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "data" / "prepared"
DEFAULT_SPLIT_NAMES = ("train", "valid", "test")

FALLBACK_PROMPT_TEMPLATE = (
    "System:\n{system}\n\n"
    "User:\n{user}\n\n"
    "Assistant:\n"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Prepare train/valid/test JSONL splits into model-ready records for baseline "
            "causal language model fine-tuning."
        )
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help=f"Directory containing split JSONL files. Defaults to {DEFAULT_INPUT_DIR}.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Directory where prepared files will be written. Defaults to {DEFAULT_OUTPUT_DIR}.",
    )
    return parser.parse_args()


def extract_message(example: dict[str, Any], role: str) -> str:
    messages = example.get("messages", [])
    if not isinstance(messages, list):
        raise ValueError("Example messages must be a list")

    for message in messages:
        if isinstance(message, dict) and message.get("role") == role:
            return str(message.get("content", ""))

    raise ValueError(f"Missing {role!r} message")


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


def render_prompt(system_prompt: str, user_prompt: str) -> str:
    return FALLBACK_PROMPT_TEMPLATE.format(system=system_prompt.strip(), user=user_prompt.strip())


def prepare_example(example: dict[str, Any], example_id: str, split_name: str) -> dict[str, Any]:
    system_prompt = extract_message(example, "system")
    user_prompt = extract_message(example, "user")
    assistant_sql = extract_message(example, "assistant").strip()
    prompt_text = render_prompt(system_prompt, user_prompt)
    messages = example["messages"]
    prompt_messages = [message for message in messages if message.get("role") != "assistant"]

    return {
        "example_id": example_id,
        "split": split_name,
        "system_prompt": system_prompt,
        "user_prompt": user_prompt,
        "assistant_sql": assistant_sql,
        "statement_type": statement_type(assistant_sql),
        "normalized_sql": normalize_sql(assistant_sql),
        "prompt_text": prompt_text,
        "train_text": f"{prompt_text}{assistant_sql}",
        "messages": messages,
        "prompt_messages": prompt_messages,
    }


def prepare_split(input_path: Path, split_name: str) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    prepared_examples: list[dict[str, Any]] = []
    statement_counts: dict[str, int] = {}

    for index, raw_line in enumerate(input_path.read_text(encoding="utf-8").splitlines(), start=1):
        if not raw_line.strip():
            continue

        example = json.loads(raw_line)
        prepared = prepare_example(example, example_id=f"{split_name}-{index:05d}", split_name=split_name)
        prepared_examples.append(prepared)
        statement_counts[prepared["statement_type"]] = statement_counts.get(prepared["statement_type"], 0) + 1

    summary = {
        "split": split_name,
        "example_count": len(prepared_examples),
        "statement_type_counts": statement_counts,
    }
    return prepared_examples, summary


def write_jsonl(path: Path, records: list[dict[str, Any]]) -> None:
    serialized = "\n".join(json.dumps(record, ensure_ascii=True) for record in records)
    if serialized:
        serialized += "\n"
    path.write_text(serialized, encoding="utf-8")


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    manifest: dict[str, Any] = {"splits": {}}

    for split_name in DEFAULT_SPLIT_NAMES:
        input_path = args.input_dir / f"{split_name}.jsonl"
        if not input_path.exists():
            raise FileNotFoundError(f"Missing split file: {input_path}")

        prepared_examples, summary = prepare_split(input_path, split_name)
        output_path = args.output_dir / f"{split_name}_prepared.jsonl"
        write_jsonl(output_path, prepared_examples)
        manifest["splits"][split_name] = {
            **summary,
            "input_path": str(input_path),
            "output_path": str(output_path),
        }

    manifest_path = args.output_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")

    print(f"Prepared files written to {args.output_dir}")
    for split_name, summary in manifest["splits"].items():
        print(f"- {split_name}: {summary['example_count']} examples")


if __name__ == "__main__":
    main()
