#!/usr/bin/env bash
# Build (if needed) and run the Node demo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$ROOT/scripts/build-rust.sh" >/dev/null

if ! command -v node >/dev/null; then
    echo "[SKIP] node: node not installed" >&2
    exit 0
fi

if [ ! -f "$ROOT/sdk/node/index.node" ]; then
    bash "$ROOT/demos/node/setup.sh" >/dev/null
fi

WEAVEFFI_ROOT="$ROOT" node "$ROOT/demos/node/demo.mjs"
