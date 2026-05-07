#!/usr/bin/env bash
# Build & run the Swift demo. We pass the C header search path and link
# search path via -Xcc / -Xlinker. The system library module.modulemap
# requests `link "weaveffi"`; SwiftPM picks that up and adds -lweaveffi.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB=$(bash "$ROOT/scripts/build-rust.sh" | tail -1)
LIB_DIR=$(dirname "$LIB")
HEADER_DIR="$ROOT/sdk/c"

cd "$ROOT/demos/swift"

WEAVEFFI_ROOT="$ROOT" swift run \
    -Xcc -I"$HEADER_DIR" \
    -Xlinker -L"$LIB_DIR" \
    -Xlinker -rpath -Xlinker "$LIB_DIR" \
    demo
