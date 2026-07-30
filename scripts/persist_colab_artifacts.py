"""Copy Colab training and evaluation artifacts from temporary disk to Google Drive."""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import UTC, datetime
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path("artifacts"))
    parser.add_argument(
        "--destination",
        type=Path,
        default=Path("/content/drive/MyDrive/text-to-sql-artifacts"),
        help="Mounted Google Drive directory that will receive a copy of the artifact tree.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    source = args.source.resolve()
    destination = args.destination.resolve()

    if not source.is_dir():
        raise SystemExit(f"Artifact directory does not exist: {source}")
    if not destination.parent.exists():
        raise SystemExit(
            f"Google Drive does not appear to be mounted at {destination.parent}. "
            "Run drive.mount('/content/drive') in Colab first."
        )

    destination.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source, destination, dirs_exist_ok=True)

    files = sorted(str(path.relative_to(destination)) for path in destination.rglob("*") if path.is_file())
    manifest = {
        "copied_at_utc": datetime.now(UTC).isoformat(),
        "source": str(source),
        "destination": str(destination),
        "files": files,
    }
    (destination / "persistence_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Copied {len(files)} artifact files to {destination}")
    print(f"Metrics: {destination / 'benchmark-full' / 'benchmark_metrics.json'}")


if __name__ == "__main__":
    main()
