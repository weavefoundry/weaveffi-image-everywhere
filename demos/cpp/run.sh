#!/usr/bin/env bash
# Build & run the C++ demo (clang++ + CommonCrypto + sdk/cpp/weaveffi.hpp).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB=$(bash "$ROOT/scripts/build-rust.sh" | tail -1)
LIB_DIR=$(dirname "$LIB")

cd "$ROOT/demos/cpp"

clang++ -std=c++17 -O2 -Wall -Wextra \
    -I"$ROOT/sdk/cpp" -I"$ROOT/sdk/c" \
    -L"$LIB_DIR" -Wl,-rpath,"$LIB_DIR" \
    -lweaveffi \
    demo.cpp -o demo

WEAVEFFI_ROOT="$ROOT" ./demo
