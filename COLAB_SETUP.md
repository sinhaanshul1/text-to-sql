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
  --output-dir /content/drive/MyDrive/text-to-sql-artifacts/qwen2.5-1.5b-lora-baseline
```

Do not run `pip install --upgrade torch ...` or install individual training
packages in the Colab base environment. To intentionally update dependencies,
change `pyproject.toml`, run `uv lock`, test locally, and commit both the
project file and `uv.lock` together.
