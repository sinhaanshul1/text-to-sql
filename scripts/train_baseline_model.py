from __future__ import annotations

import argparse
import inspect
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PREPARED_DIR = PROJECT_ROOT / "data" / "prepared"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "artifacts" / "baseline-model"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Fine-tune a baseline causal language model on prepared text-to-SQL examples. "
            "The prompt tokens are masked so training loss is applied only to the assistant SQL."
        )
    )
    parser.add_argument(
        "--model-name-or-path",
        required=True,
        help="Hugging Face model identifier or a local model path.",
    )
    parser.add_argument(
        "--prepared-dir",
        type=Path,
        default=DEFAULT_PREPARED_DIR,
        help=f"Directory containing *_prepared.jsonl files. Defaults to {DEFAULT_PREPARED_DIR}.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Directory where fine-tuned artifacts will be written. Defaults to {DEFAULT_OUTPUT_DIR}.",
    )
    parser.add_argument("--max-length", type=int, default=768, help="Maximum token length per example.")
    parser.add_argument("--num-train-epochs", type=float, default=3.0, help="Number of training epochs.")
    parser.add_argument("--learning-rate", type=float, default=2e-5, help="Optimizer learning rate.")
    parser.add_argument("--train-batch-size", type=int, default=4, help="Per-device train batch size.")
    parser.add_argument("--eval-batch-size", type=int, default=4, help="Per-device eval batch size.")
    parser.add_argument(
        "--gradient-accumulation-steps",
        type=int,
        default=4,
        help="Gradient accumulation steps.",
    )
    parser.add_argument("--weight-decay", type=float, default=0.01, help="Weight decay.")
    parser.add_argument("--warmup-ratio", type=float, default=0.03, help="Warmup ratio.")
    parser.add_argument(
        "--logging-steps",
        type=int,
        default=10,
        help="How often to emit training logs.",
    )
    parser.add_argument(
        "--save-strategy",
        default="epoch",
        choices=("no", "steps", "epoch"),
        help="Checkpoint save strategy.",
    )
    parser.add_argument(
        "--evaluation-strategy",
        default="epoch",
        choices=("no", "steps", "epoch"),
        help="Evaluation strategy.",
    )
    parser.add_argument(
        "--use-lora",
        action="store_true",
        help="Apply LoRA adapters with PEFT instead of full fine-tuning.",
    )
    parser.add_argument("--lora-r", type=int, default=16, help="LoRA rank.")
    parser.add_argument("--lora-alpha", type=int, default=32, help="LoRA alpha.")
    parser.add_argument("--lora-dropout", type=float, default=0.05, help="LoRA dropout.")
    return parser.parse_args()


def require_training_dependencies() -> tuple[Any, Any, Any, Any, Any, Any]:
    try:
        import torch
        from datasets import Dataset
        from transformers import AutoModelForCausalLM, AutoTokenizer, Trainer, TrainingArguments
    except ImportError as exc:  # noqa: BLE001
        raise SystemExit(
            "Missing training dependencies. Install at least: transformers datasets torch accelerate"
        ) from exc

    return torch, Dataset, AutoModelForCausalLM, AutoTokenizer, TrainingArguments, Trainer


def maybe_require_lora() -> tuple[Any, Any]:
    try:
        from peft import LoraConfig, get_peft_model
    except ImportError as exc:  # noqa: BLE001
        raise SystemExit("Missing PEFT dependency. Install peft to use --use-lora.") from exc

    return LoraConfig, get_peft_model


def load_prepared_records(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if raw_line.strip():
            records.append(json.loads(raw_line))
    return records


@dataclass
class TokenizedRecord:
    input_ids: list[int]
    attention_mask: list[int]
    labels: list[int]


def supports_chat_template(tokenizer: Any) -> bool:
    chat_template = getattr(tokenizer, "chat_template", None)
    return isinstance(chat_template, str) and bool(chat_template.strip())


def build_chat_template_kwargs(tokenizer: Any, add_generation_prompt: bool) -> dict[str, Any]:
    kwargs: dict[str, Any] = {
        "tokenize": False,
        "add_generation_prompt": add_generation_prompt,
    }

    signature = inspect.signature(tokenizer.apply_chat_template)
    if "enable_thinking" in signature.parameters:
        # Keep SQL outputs concise for training/inference formatting on hybrid reasoning models.
        kwargs["enable_thinking"] = False

    return kwargs


def render_record_texts(record: dict[str, Any], tokenizer: Any) -> tuple[str, str]:
    if supports_chat_template(tokenizer):
        full_messages = record["messages"]
        prompt_messages = record.get("prompt_messages")
        if not prompt_messages:
            prompt_messages = [message for message in full_messages if message.get("role") != "assistant"]

        prompt_text = tokenizer.apply_chat_template(
            prompt_messages,
            **build_chat_template_kwargs(tokenizer, add_generation_prompt=True),
        )
        train_text = tokenizer.apply_chat_template(
            full_messages,
            **build_chat_template_kwargs(tokenizer, add_generation_prompt=False),
        )
        return str(prompt_text), str(train_text)

    return str(record["prompt_text"]), str(record["train_text"])


def encode_record(record: dict[str, Any], tokenizer: Any, max_length: int) -> TokenizedRecord:
    prompt_text, train_text = render_record_texts(record, tokenizer)

    full_encoding = tokenizer(
        train_text,
        truncation=True,
        max_length=max_length,
        add_special_tokens=True,
    )
    prompt_encoding = tokenizer(
        prompt_text,
        truncation=True,
        max_length=max_length,
        add_special_tokens=True,
    )

    input_ids = list(full_encoding["input_ids"])
    attention_mask = list(full_encoding["attention_mask"])
    labels = list(input_ids)

    prompt_length = min(len(prompt_encoding["input_ids"]), len(labels))
    for index in range(prompt_length):
        labels[index] = -100

    if all(label == -100 for label in labels):
        raise ValueError(f"Prompt consumed the entire sequence for example {record['example_id']}")

    return TokenizedRecord(
        input_ids=input_ids,
        attention_mask=attention_mask,
        labels=labels,
    )


class SqlDataCollator:
    def __init__(self, tokenizer: Any) -> None:
        self.tokenizer = tokenizer

    def __call__(self, features: list[dict[str, list[int]]]) -> dict[str, Any]:
        max_length = max(len(feature["input_ids"]) for feature in features)
        pad_token_id = self.tokenizer.pad_token_id

        batch_input_ids: list[list[int]] = []
        batch_attention_mask: list[list[int]] = []
        batch_labels: list[list[int]] = []

        for feature in features:
            pad_size = max_length - len(feature["input_ids"])
            batch_input_ids.append(feature["input_ids"] + [pad_token_id] * pad_size)
            batch_attention_mask.append(feature["attention_mask"] + [0] * pad_size)
            batch_labels.append(feature["labels"] + [-100] * pad_size)

        import torch

        return {
            "input_ids": torch.tensor(batch_input_ids, dtype=torch.long),
            "attention_mask": torch.tensor(batch_attention_mask, dtype=torch.long),
            "labels": torch.tensor(batch_labels, dtype=torch.long),
        }


def main() -> None:
    args = parse_args()
    torch, Dataset, AutoModelForCausalLM, AutoTokenizer, TrainingArguments, Trainer = require_training_dependencies()

    train_path = args.prepared_dir / "train_prepared.jsonl"
    valid_path = args.prepared_dir / "valid_prepared.jsonl"
    if not train_path.exists() or not valid_path.exists():
        raise FileNotFoundError(
            "Prepared training files are missing. Run scripts/prepare_training_inputs.py first."
        )

    train_records = load_prepared_records(train_path)
    valid_records = load_prepared_records(valid_path)

    tokenizer = AutoTokenizer.from_pretrained(args.model_name_or_path, use_fast=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(args.model_name_or_path)
    model.config.pad_token_id = tokenizer.pad_token_id

    if args.use_lora:
        LoraConfig, get_peft_model = maybe_require_lora()
        lora_config = LoraConfig(
            r=args.lora_r,
            lora_alpha=args.lora_alpha,
            lora_dropout=args.lora_dropout,
            bias="none",
            task_type="CAUSAL_LM",
        )
        model = get_peft_model(model, lora_config)

    if supports_chat_template(tokenizer):
        print(f"Using tokenizer chat template for {args.model_name_or_path}")
    else:
        print(f"Tokenizer has no chat template; falling back to plain-text prompt formatting for {args.model_name_or_path}")

    def tokenize_records(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        tokenized_rows: list[dict[str, Any]] = []
        for record in records:
            encoded = encode_record(record, tokenizer, max_length=args.max_length)
            tokenized_rows.append(
                {
                    "input_ids": encoded.input_ids,
                    "attention_mask": encoded.attention_mask,
                    "labels": encoded.labels,
                }
            )
        return tokenized_rows

    train_dataset = Dataset.from_list(tokenize_records(train_records))
    valid_dataset = Dataset.from_list(tokenize_records(valid_records))

    training_arguments = TrainingArguments(
        output_dir=str(args.output_dir),
        learning_rate=args.learning_rate,
        per_device_train_batch_size=args.train_batch_size,
        per_device_eval_batch_size=args.eval_batch_size,
        gradient_accumulation_steps=args.gradient_accumulation_steps,
        num_train_epochs=args.num_train_epochs,
        weight_decay=args.weight_decay,
        warmup_ratio=args.warmup_ratio,
        logging_steps=args.logging_steps,
        save_strategy=args.save_strategy,
        evaluation_strategy=args.evaluation_strategy,
        report_to=[],
        fp16=torch.cuda.is_available(),
        remove_unused_columns=False,
    )

    trainer = Trainer(
        model=model,
        args=training_arguments,
        train_dataset=train_dataset,
        eval_dataset=valid_dataset,
        data_collator=SqlDataCollator(tokenizer),
    )

    trainer.train()
    trainer.save_model()
    tokenizer.save_pretrained(args.output_dir)

    metrics = trainer.evaluate()
    metrics_path = args.output_dir / "eval_metrics.json"
    args.output_dir.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(json.dumps(metrics, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")

    print(f"Saved fine-tuned artifacts to {args.output_dir}")
    print(f"Saved evaluation metrics to {metrics_path}")


if __name__ == "__main__":
    main()
