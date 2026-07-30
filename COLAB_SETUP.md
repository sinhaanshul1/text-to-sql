# Google Colab setup

Use a fresh Colab GPU runtime, clone the repository, and run the following cells in order.

```python
!pip install --quiet uv
!git clone https://github.com/sinhaanshul1/text-to-sql.git
%cd /content/text-to-sql
!uv sync --locked
```

`uv sync --locked` installs the exact packages recorded in `uv.lock` into this
project's `.venv`. It does not alter Colab's shared Python installation.

Prepare the data and train through that isolated environment:

```python
!uv run python scripts/prepare_training_inputs.py

!uv run python scripts/train_baseline_model.py \
  --model-name-or-path Qwen/Qwen2.5-1.5B-Instruct \
  --use-lora \
  --max-length 512 \
  --train-batch-size 1 \
  --eval-batch-size 1 \
  --gradient-accumulation-steps 8 \
  --output-dir artifacts/qwen2.5-1.5b-lora-baseline
```

## Persist artifacts and metrics

Everything below `/content` is deleted when the Colab runtime disconnects.
Mount Drive once near the top of the notebook, then copy artifacts after
training and after benchmarking:

```python
from google.colab import drive
drive.mount("/content/drive")
```

```python
%cd /content/text-to-sql
!uv run python scripts/persist_colab_artifacts.py \
  --source artifacts \
  --destination /content/drive/MyDrive/text-to-sql-artifacts
```

This persists the adapter, `eval_metrics.json`, the full benchmark report
(`benchmark-full/benchmark_metrics.json`), predictions, and failure logs.
The report includes correctness, executability, result-match accuracy, TTFT,
latency, throughput, VRAM usage, adapter size, and input-token reduction.

Do not run `pip install --upgrade torch ...` or install individual training
packages in the Colab base environment. To intentionally update dependencies,
change `pyproject.toml`, run `uv lock`, test locally, and commit both the
project file and `uv.lock` together.
