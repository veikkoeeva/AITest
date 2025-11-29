#!/usr/bin/env python3
"""Update package lock file using uv."""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT: Path = Path(__file__).resolve().parent
PYPROJECT: Path = ROOT / "pyproject.toml"


def ensure_uv() -> None:
    """Install uv if not available."""
    if shutil.which("uv") is not None:
        return

    print("uv not found. Installing...")

    if sys.platform == "win32":
        subprocess.run(
            ["powershell", "-ExecutionPolicy", "ByPass", "-c",
             "irm https://astral.sh/uv/install.ps1 | iex"],
            check=True,
        )
        # Add to PATH for current process
        uv_path = Path.home() / ".local" / "bin"
        if uv_path.exists():
            os.environ["PATH"] = f"{uv_path};{os.environ.get('PATH', '')}"
    else:
        subprocess.run(
            ["sh", "-c", "curl -LsSf https://astral.sh/uv/install.sh | sh"],
            check=True,
        )
        # Add to PATH for current process
        uv_path = Path.home() / ".local" / "bin"
        if uv_path.exists():
            os.environ["PATH"] = f"{uv_path}:{os.environ.get('PATH', '')}"

    if shutil.which("uv") is None:
        print("Error: uv installed but not found in PATH. Restart your shell.", file=sys.stderr)
        sys.exit(1)

    print("uv installed successfully.\n")


def main() -> None:
    """Main entry point."""
    if not PYPROJECT.exists():
        print(f"Error: {PYPROJECT} not found", file=sys.stderr)
        sys.exit(1)

    print(f"Using: {PYPROJECT}\n")

    ensure_uv()

    # uv lock updates/creates uv.lock from pyproject.toml
    print("Updating lock file…")
    subprocess.run(["uv", "lock", "--upgrade"], check=True, cwd=ROOT)

    print("\nDone! Updated:")
    print(f"  - {ROOT / 'uv.lock'}")


if __name__ == "__main__":
    main()