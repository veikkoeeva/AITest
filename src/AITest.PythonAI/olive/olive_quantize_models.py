#!/usr/bin/env python3
"""ONNX Model Conversion to FP16 using Olive."""
from __future__ import annotations

import json
import os
import sys
import urllib.request
from pathlib import Path
from typing import Any


def download_model(model_url: str, model_dir: Path, model_name: str) -> Path:
    """
    Download a model from the given URL if it doesn't already exist locally.

    Args:
        model_url: The URL from which to download the model.
        model_dir: The directory where the model will be saved.
        model_name: The name of the model file to be saved.

    Returns:
        The path to the downloaded (or existing) model file.
    """
    model_path = model_dir / model_name
    model_dir.mkdir(parents=True, exist_ok=True)

    if not model_path.exists():
        print(f"Downloading model from {model_url}...")
        urllib.request.urlretrieve(model_url, model_path)
        print(f"Model downloaded to {model_path}")
    else:
        print(f"Model already exists at {model_path}")

    return model_path


def run_olive_workflow(config_path: Path) -> None:
    """
    Execute the Olive workflow using the specified configuration file.

    Args:
        config_path: Path to the Olive workflow configuration JSON file.

    Raises:
        FileNotFoundError: If the configuration file does not exist.
    """
    from olive.workflows import run as olive_run

    config_path = config_path.resolve()
    print(f"Running Olive workflow with config: {config_path}")

    if not config_path.exists():
        raise FileNotFoundError(f"[ERROR] Configuration file not found: {config_path}")

    config_data: dict[str, Any] = json.loads(config_path.read_text())
    print(json.dumps(config_data, indent=2))

    olive_run(str(config_path))
    print("[OK] Olive workflow completed.")


def main() -> None:
    """Main entry point."""
    print(f"Python executable: {sys.executable}")
    print(f"Current working directory: {os.getcwd()}")

    model_url = "https://github.com/onnx/models/raw/main/validated/vision/classification/resnet/model/resnet50-v2-7.onnx"
    model_dir = Path("artifacts/models/resnet50")
    model_name = "resnet50-v2-7.onnx"

    script_dir = Path(__file__).resolve().parent
    olive_config_path = script_dir / "olive_quantize_cpu_to_fp16.json"

    print(f"Using Olive config: {olive_config_path}")

    download_model(model_url, model_dir, model_name)
    run_olive_workflow(olive_config_path)


if __name__ == "__main__":
    main()