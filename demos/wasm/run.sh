#!/usr/bin/env bash
# Build the WASM facade and run the demo via Node's WebAssembly runtime.
# Requires: rustup target add wasm32-unknown-unknown, node 18+.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if ! rustup target list --installed | grep -q wasm32-unknown-unknown; then
    echo "==> rustup target add wasm32-unknown-unknown"
    rustup target add wasm32-unknown-unknown
fi

echo "==> cargo build --release --target wasm32-unknown-unknown -p weaveffi-image"
cargo build --release --target wasm32-unknown-unknown -p weaveffi-image \
    --manifest-path "$ROOT/Cargo.toml"

cd "$ROOT/demos/wasm"
node demo.mjs
