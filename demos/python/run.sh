#!/usr/bin/env bash
# Run the Python demo. Requires python 3.9+.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$ROOT/scripts/build-rust.sh" >/dev/null

if ! command -v python3 >/dev/null; then
    echo "[SKIP] python: python3 not installed" >&2
    exit 0
fi

WEAVEFFI_ROOT="$ROOT" python3 "$ROOT/demos/python/demo.py"
