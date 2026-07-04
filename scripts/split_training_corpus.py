from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
from collections import defaultdict
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATASET_PATH = PROJECT_ROOT / "data" / "training_corpus.jsonl"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "data"

SPLIT_RATIOS = {
    "train": 0.8,
    "valid": 0.1,
    "test": 0.1,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Split the fine-tuning corpus into train, validation, and test files while "
            "keeping paraphrase variants of the same SQL in the same split."
        )
    )
    parser.add_argument(
        "--dataset-path",
        type=Path,
        default=DEFAULT_DATASET_PATH,
        help=f"Path to the source JSONL dataset. Defaults to {DEFAULT_DATASET_PATH}.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Directory where split JSONL files will be written. Defaults to {DEFAULT_OUTPUT_DIR}.",
    )
    return parser.parse_args()


def load_examples(dataset_path: Path) -> list[dict[str, object]]:
    examples: list[dict[str, object]] = []
    for raw_line in dataset_path.read_text(encoding="utf-8").splitlines():
        if raw_line.strip():
            examples.append(json.loads(raw_line))
    return examples


def extract_message(example: dict[str, object], role: str) -> str:
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
        return "unknown"
    statement = match.group(1).upper()
    if statement == "WITH":
        return "SELECT"
    return statement


def stable_group_key(sql: str) -> str:
    return hashlib.sha256(normalize_sql(sql).encode("utf-8")).hexdigest()


def compute_split_targets(group_sizes: list[int]) -> dict[str, int]:
    total_examples = sum(group_sizes)
    raw_targets = {name: total_examples * ratio for name, ratio in SPLIT_RATIOS.items()}
    targets = {name: math.floor(raw_value) for name, raw_value in raw_targets.items()}
    remainder = total_examples - sum(targets.values())

    for split_name, _ in sorted(
        raw_targets.items(),
        key=lambda item: (item[1] - math.floor(item[1]), item[0]),
        reverse=True,
    )[:remainder]:
        targets[split_name] += 1

    return targets


def choose_split(
    group_size: int,
    counts: dict[str, int],
    targets: dict[str, int],
    split_name_order: list[str],
) -> str:
    def score(name: str) -> tuple[int, int]:
        projected_gap = targets[name] - (counts[name] + group_size)
        current_gap = targets[name] - counts[name]

        if projected_gap >= 0:
            penalty = projected_gap
        else:
            penalty = abs(projected_gap) + total_target_examples(targets)

        return (penalty, -current_gap)

    return min(split_name_order, key=score)


def total_target_examples(targets: dict[str, int]) -> int:
    return sum(targets.values())


def split_examples(examples: list[dict[str, object]]) -> tuple[dict[str, list[dict[str, object]]], dict[str, object]]:
    grouped_examples: dict[str, list[dict[str, object]]] = defaultdict(list)
    group_statement_types: dict[str, str] = {}

    for example in examples:
        sql = extract_message(example, "assistant")
        group_key = stable_group_key(sql)
        grouped_examples[group_key].append(example)
        group_statement_types[group_key] = statement_type(sql)

    statement_buckets: dict[str, list[str]] = defaultdict(list)
    for group_key, group_type in group_statement_types.items():
        statement_buckets[group_type].append(group_key)

    split_examples_map: dict[str, list[dict[str, object]]] = {name: [] for name in SPLIT_RATIOS}
    split_group_keys: dict[str, list[str]] = {name: [] for name in SPLIT_RATIOS}
    split_counts: dict[str, int] = {name: 0 for name in SPLIT_RATIOS}
    per_statement_summary: dict[str, dict[str, int]] = {}

    split_name_order = list(SPLIT_RATIOS.keys())

    for statement_name, group_keys in sorted(statement_buckets.items()):
        sorted_group_keys = sorted(
            group_keys,
            key=lambda key: (-len(grouped_examples[key]), key),
        )
        targets = compute_split_targets([len(grouped_examples[key]) for key in sorted_group_keys])
        bucket_counts = {name: 0 for name in SPLIT_RATIOS}

        for group_key in sorted_group_keys:
            group = grouped_examples[group_key]
            split_name = choose_split(len(group), bucket_counts, targets, split_name_order)
            bucket_counts[split_name] += len(group)
            split_counts[split_name] += len(group)
            split_group_keys[split_name].append(group_key)
            split_examples_map[split_name].extend(group)

        per_statement_summary[statement_name] = bucket_counts

    summary = {
        "total_examples": len(examples),
        "split_counts": split_counts,
        "group_counts": {name: len(keys) for name, keys in split_group_keys.items()},
        "statement_type_counts": per_statement_summary,
    }
    return split_examples_map, summary


def verify_no_overlap(split_examples_map: dict[str, list[dict[str, object]]]) -> None:
    split_fingerprints: dict[str, set[str]] = {}

    for split_name, examples in split_examples_map.items():
        split_fingerprints[split_name] = {
            stable_group_key(extract_message(example, "assistant")) for example in examples
        }

    split_names = list(split_examples_map.keys())
    for index, left_name in enumerate(split_names):
        for right_name in split_names[index + 1 :]:
            overlap = split_fingerprints[left_name] & split_fingerprints[right_name]
            if overlap:
                raise ValueError(
                    f"Found {len(overlap)} overlapping SQL groups between {left_name} and {right_name}"
                )


def write_split_files(output_dir: Path, split_examples_map: dict[str, list[dict[str, object]]]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for split_name, examples in split_examples_map.items():
        output_path = output_dir / f"{split_name}.jsonl"
        serialized = "\n".join(json.dumps(example, ensure_ascii=True) for example in examples)
        if serialized:
            serialized += "\n"
        output_path.write_text(serialized, encoding="utf-8")


def main() -> None:
    args = parse_args()

    examples = load_examples(args.dataset_path)
    split_examples_map, summary = split_examples(examples)
    verify_no_overlap(split_examples_map)
    write_split_files(args.output_dir, split_examples_map)

    print(f"Source examples: {summary['total_examples']}")
    print("Split counts:")
    for split_name, count in summary["split_counts"].items():
        print(f"- {split_name}: {count}")

    print("Grouped SQL fingerprints:")
    for split_name, count in summary["group_counts"].items():
        print(f"- {split_name}: {count}")

    print("Statement-type distribution:")
    for statement_name, counts in sorted(summary["statement_type_counts"].items()):
        joined_counts = ", ".join(f"{split_name}={count}" for split_name, count in counts.items())
        print(f"- {statement_name}: {joined_counts}")


if __name__ == "__main__":
    main()
