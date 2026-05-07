#!/usr/bin/env bash
# Build & run the Go demo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v go >/dev/null; then
    echo "[SKIP] go: go not installed" >&2
    exit 0
fi

eval "$(bash "$ROOT/demos/go/setup.sh")"
cd "$ROOT/demos/go"
go run .
