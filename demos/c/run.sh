#!/usr/bin/env bash
# Build & run the C demo (macOS clang + CommonCrypto for SHA).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB=$(bash "$ROOT/scripts/build-rust.sh" | tail -1)
LIB_DIR=$(dirname "$LIB")
HEADER_DIR="$ROOT/sdk/c"

cd "$ROOT/demos/c"

clang -O2 -Wall -Wextra \
    -I"$HEADER_DIR" \
    -L"$LIB_DIR" -Wl,-rpath,"$LIB_DIR" \
    -lweaveffi \
    demo.c -o demo

WEAVEFFI_ROOT="$ROOT" ./demo
