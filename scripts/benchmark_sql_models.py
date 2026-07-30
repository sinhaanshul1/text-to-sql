from __future__ import annotations

import argparse
import json
import statistics
import time
from dataclasses import dataclass
from pathlib import Path
from threading import Thread
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PREPARED_DIR = PROJECT_ROOT / "data" / "prepared"
DEFAULT_DB_PATH = PROJECT_ROOT / "data" / "shopify_sample.db"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "artifacts" / "benchmark"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark a base causal language model against a LoRA SQL adapter on a held-out split."
    )
    parser.add_argument("--base-model", required=True, help="Hugging Face base model ID or local path.")
    parser.add_argument("--adapter-path", type=Path, required=True, help="Directory containing the saved LoRA adapter.")
    parser.add_argument("--prepared-dir", type=Path, default=DEFAULT_PREPARED_DIR)
    parser.add_argument("--split", default="test", choices=("train", "valid", "test"))
    parser.add_argument("--db-path", type=Path, default=DEFAULT_DB_PATH)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--max-new-tokens", type=int, default=256)
    parser.add_argument("--max-examples", type=int, default=None, help="Limit examples for a smoke benchmark.")
    parser.add_argument(
        "--schema-path",
        type=Path,
        default=None,
        help="Optional schema file. Used for token-economics reporting and optional base-model context.",
    )
    parser.add_argument(
        "--baseline-include-schema",
        action="store_true",
        help="Append the supplied schema to the base-model system prompt. The adapter remains schema-free.",
    )
    return parser.parse_args()


def require_dependencies() -> tuple[Any, Any, Any, Any, Any]:
    try:
        import torch
        from peft import PeftModel
        from transformers import AutoModelForCausalLM, AutoTokenizer
        from transformers.generation.streamers import BaseStreamer
    except ImportError as exc:  # noqa: BLE001
        raise SystemExit("Install the locked project environment with `uv sync --locked` before benchmarking.") from exc
    return torch, PeftModel, AutoModelForCausalLM, AutoTokenizer, BaseStreamer


def load_records(path: Path, max_examples: int | None) -> list[dict[str, Any]]:
    records = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    return records if max_examples is None else records[:max_examples]


def file_size_bytes(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(item.stat().st_size for item in path.rglob("*") if item.is_file())


def clean_sql(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        lines = text.splitlines()
        lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        text = "\n".join(lines).strip()
    return text


def percentile(values: list[float], fraction: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def with_rates(metrics: dict[str, Any]) -> dict[str, Any]:
    result = dict(metrics)
    total = result.pop("count", 0)
    result["examples"] = total
    for name, value in list(result.items()):
        if isinstance(value, int):
            result[f"{name}_rate"] = value / total if total else 0.0
    return result


def render_prompt(record: dict[str, Any], tokenizer: Any, schema_context: str | None) -> str:
    # This file is executed directly (``python scripts/benchmark_sql_models.py``),
    # so Python places ``scripts/`` rather than the repository root on sys.path.
    # Import the sibling module accordingly.
    from train_baseline_model import build_chat_template_kwargs, supports_chat_template

    if supports_chat_template(tokenizer):
        messages = [dict(message) for message in record["prompt_messages"]]
        if schema_context:
            for message in messages:
                if message.get("role") == "system":
                    message["content"] = f"{message['content'].rstrip()}\n\nDatabase schema:\n{schema_context}"
                    break
            else:
                messages.insert(0, {"role": "system", "content": f"Database schema:\n{schema_context}"})
        return str(tokenizer.apply_chat_template(messages, **build_chat_template_kwargs(tokenizer, True)))

    system_prompt = str(record["system_prompt"])
    if schema_context:
        system_prompt = f"{system_prompt.rstrip()}\n\nDatabase schema:\n{schema_context}"
    return f"{system_prompt}\n\nUser: {record['user_prompt']}\nAssistant:"


@dataclass
class Generation:
    sql: str
    prompt_tokens: int
    completion_tokens: int
    ttft_seconds: float
    total_latency_seconds: float


def generate_one(model: Any, tokenizer: Any, prompt: str, max_new_tokens: int, torch: Any, base_streamer: Any) -> Generation:
    class TimingTokenStreamer(base_streamer):
        def __init__(self) -> None:
            self.skip_prompt = True
            self.first_token_at: float | None = None
            self.token_ids: list[int] = []

        def put(self, value: Any) -> None:
            values = value.tolist()
            if values and isinstance(values[0], list):
                values = values[0]
            if self.skip_prompt:
                self.skip_prompt = False
                return
            if values:
                if self.first_token_at is None:
                    self.first_token_at = time.perf_counter()
                self.token_ids.extend(values)

        def end(self) -> None:
            return None

    device = next(model.parameters()).device
    encoded = tokenizer(prompt, return_tensors="pt", add_special_tokens=True).to(device)
    streamer = TimingTokenStreamer()
    started_at = time.perf_counter()
    generation_error: list[BaseException] = []

    def run_generation() -> None:
        try:
            model.generate(
                **encoded,
                max_new_tokens=max_new_tokens,
                do_sample=False,
                pad_token_id=tokenizer.pad_token_id,
                eos_token_id=tokenizer.eos_token_id,
                streamer=streamer,
            )
        except BaseException as exc:  # noqa: BLE001
            generation_error.append(exc)

    generation_thread = Thread(target=run_generation)
    generation_thread.start()
    generation_thread.join()
    completed_at = time.perf_counter()
    if generation_error:
        raise RuntimeError("Model generation failed") from generation_error[0]
    first_token_at = streamer.first_token_at or completed_at
    return Generation(
        sql=clean_sql(tokenizer.decode(streamer.token_ids, skip_special_tokens=True)),
        prompt_tokens=int(encoded["input_ids"].shape[-1]),
        completion_tokens=len(streamer.token_ids),
        ttft_seconds=first_token_at - started_at,
        total_latency_seconds=completed_at - started_at,
    )


def benchmark_model(
    label: str,
    model: Any,
    tokenizer: Any,
    records: list[dict[str, Any]],
    output_dir: Path,
    max_new_tokens: int,
    schema_context: str | None,
    torch: Any,
    base_streamer: Any,
) -> dict[str, Any]:
    model.eval()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.reset_peak_memory_stats()

    predictions_path = output_dir / f"predictions_{label}.jsonl"
    generations: list[dict[str, Any]] = []
    with torch.inference_mode(), predictions_path.open("w", encoding="utf-8") as handle:
        for record in records:
            prompt = render_prompt(record, tokenizer, schema_context)
            generated = generate_one(model, tokenizer, prompt, max_new_tokens, torch, base_streamer)
            row = {
                "example_id": record["example_id"],
                "prediction_sql": generated.sql,
                "prompt_tokens": generated.prompt_tokens,
                "completion_tokens": generated.completion_tokens,
                "ttft_seconds": generated.ttft_seconds,
                "total_latency_seconds": generated.total_latency_seconds,
            }
            handle.write(json.dumps(row, ensure_ascii=True) + "\n")
            generations.append(row)

    ttft = [row["ttft_seconds"] for row in generations]
    latency = [row["total_latency_seconds"] for row in generations]
    prompts = [row["prompt_tokens"] for row in generations]
    completions = [row["completion_tokens"] for row in generations]
    decode_seconds = sum(max(row["total_latency_seconds"] - row["ttft_seconds"], 0.0) for row in generations)
    summary: dict[str, Any] = {
        "label": label,
        "predictions_path": str(predictions_path),
        "examples": len(generations),
        "prompt_tokens_total": sum(prompts),
        "prompt_tokens_mean": statistics.mean(prompts) if prompts else 0.0,
        "completion_tokens_total": sum(completions),
        "completion_tokens_mean": statistics.mean(completions) if completions else 0.0,
        "ttft_seconds_mean": statistics.mean(ttft) if ttft else 0.0,
        "ttft_seconds_median": statistics.median(ttft) if ttft else 0.0,
        "ttft_seconds_p95": percentile(ttft, 0.95),
        "total_latency_seconds_mean": statistics.mean(latency) if latency else 0.0,
        "total_latency_seconds_median": statistics.median(latency) if latency else 0.0,
        "total_latency_seconds_p95": percentile(latency, 0.95),
        "completion_tokens_per_second": sum(completions) / decode_seconds if decode_seconds else 0.0,
        "schema_in_prompt": schema_context is not None,
    }
    if torch.cuda.is_available():
        summary["peak_vram_allocated_bytes"] = torch.cuda.max_memory_allocated()
        summary["peak_vram_reserved_bytes"] = torch.cuda.max_memory_reserved()
    return summary


def main() -> None:
    args = parse_args()
    torch, PeftModel, AutoModelForCausalLM, AutoTokenizer, BaseStreamer = require_dependencies()
    prepared_path = args.prepared_dir / f"{args.split}_prepared.jsonl"
    if not prepared_path.exists():
        raise FileNotFoundError(f"Missing prepared split: {prepared_path}. Run prepare_training_inputs.py first.")
    if args.baseline_include_schema and args.schema_path is None:
        raise ValueError("--baseline-include-schema requires --schema-path")

    records = load_records(prepared_path, args.max_examples)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    schema_text = args.schema_path.read_text(encoding="utf-8") if args.schema_path else None

    tokenizer = AutoTokenizer.from_pretrained(args.base_model, use_fast=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    model_kwargs: dict[str, Any] = {}
    if torch.cuda.is_available():
        model_kwargs["torch_dtype"] = torch.float16
    base_load_started_at = time.perf_counter()
    base_model = AutoModelForCausalLM.from_pretrained(args.base_model, **model_kwargs)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    base_model.to(device)

    base_load_seconds = time.perf_counter() - base_load_started_at
    benchmark_summaries = [
        benchmark_model(
            "base",
            base_model,
            tokenizer,
            records,
            args.output_dir,
            args.max_new_tokens,
            schema_text if args.baseline_include_schema else None,
            torch,
            BaseStreamer,
        )
    ]
    benchmark_summaries[0]["model_load_seconds"] = base_load_seconds
    adapter_load_started_at = time.perf_counter()
    adapted_model = PeftModel.from_pretrained(base_model, args.adapter_path)
    adapter_load_seconds = time.perf_counter() - adapter_load_started_at
    benchmark_summaries.append(
        benchmark_model(
            "adapter",
            adapted_model,
            tokenizer,
            records,
            args.output_dir,
            args.max_new_tokens,
            None,
            torch,
            BaseStreamer,
        )
    )
    benchmark_summaries[-1]["adapter_load_seconds"] = adapter_load_seconds

    from evaluate_sql_predictions import evaluate_predictions, initialize_database, load_jsonl

    initialize_database(args.db_path, reset=True)
    reference_lines = load_jsonl(PROJECT_ROOT / "data" / f"{args.split}.jsonl")
    reference_lines = reference_lines[: len(records)]
    evaluation: dict[str, Any] = {}
    for summary in benchmark_summaries:
        predictions = load_jsonl(Path(summary["predictions_path"]))
        raw_metrics, failures = evaluate_predictions(reference_lines, predictions, args.db_path)
        evaluation[summary["label"]] = {
            "overall": with_rates({"count": len(reference_lines), **raw_metrics["overall"]}),
            "by_statement_group": {
                group: with_rates(group_metrics) for group, group_metrics in raw_metrics["by_statement_group"].items()
            },
            "failure_count": len(failures),
        }
        (args.output_dir / f"failures_{summary['label']}.jsonl").write_text(
            "".join(json.dumps(failure, ensure_ascii=True) + "\n" for failure in failures), encoding="utf-8"
        )

    schema_tokens = 0
    if schema_text:
        schema_tokens = len(tokenizer(schema_text, add_special_tokens=False)["input_ids"])
    report = {
        "configuration": {
            "base_model": args.base_model,
            "adapter_path": str(args.adapter_path),
            "split": args.split,
            "max_new_tokens": args.max_new_tokens,
            "schema_tokens": schema_tokens,
            "adapter_artifact_bytes": file_size_bytes(args.adapter_path),
        },
        "generation": benchmark_summaries,
        "correctness": evaluation,
    }
    if schema_tokens:
        adapter_prompt_total = next(summary for summary in benchmark_summaries if summary["label"] == "adapter")["prompt_tokens_total"]
        report["token_economics"] = {
            "schema_tokens_per_request": schema_tokens,
            "adapter_input_tokens_total": adapter_prompt_total,
            "estimated_schema_in_context_tokens_total": adapter_prompt_total + schema_tokens * len(records),
            "estimated_input_token_reduction_rate": schema_tokens * len(records)
            / (adapter_prompt_total + schema_tokens * len(records)),
        }
    report_path = args.output_dir / "benchmark_metrics.json"
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, ensure_ascii=True))
    print(f"Saved benchmark report to {report_path}")


if __name__ == "__main__":
    main()
