#!/usr/bin/env bash
# Build env for `go run` / `go build` against the WeaveFFI Go SDK. The
# generated weaveffi.go has `#cgo LDFLAGS: -lweaveffi` and includes
# weaveffi.h, so CGo needs to find both.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB=$(bash "$ROOT/scripts/build-rust.sh" | tail -1)
LIB_DIR=$(dirname "$LIB")
HEADER_DIR="$ROOT/sdk/c"

cat <<EOF
# Eval this in a shell to run the demo:
#   eval "\$(bash $0)"
#   cd $ROOT/demos/go && go run .
export CGO_CFLAGS="-I$HEADER_DIR"
export CGO_LDFLAGS="-L$LIB_DIR -lweaveffi -Wl,-rpath,$LIB_DIR"
EOF
