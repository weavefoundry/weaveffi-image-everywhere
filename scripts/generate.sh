#!/usr/bin/env bash
# Run weaveffi generate for every supported target with --scaffold.
#
# Output goes to ./sdk/. The committed contents of ./sdk/ should always
# match what this script produces from image.yml — we run
# `weaveffi diff --check` in CI to enforce that.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v weaveffi >/dev/null 2>&1; then
    echo "ERROR: weaveffi CLI not found on PATH." >&2
    echo "Install with: cargo install weaveffi-cli --version 0.4.0" >&2
    exit 1
fi

echo "==> weaveffi $(weaveffi --version)  /  schema $(weaveffi schema-version)"
weaveffi validate image.yml
weaveffi lint image.yml

rm -rf sdk
weaveffi generate image.yml \
    -o sdk \
    --target c,cpp,swift,android,node,wasm,python,dotnet,dart,go,ruby \
    --scaffold

echo "[OK] generated SDKs in sdk/"
ls sdk/
