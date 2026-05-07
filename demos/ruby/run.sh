#!/usr/bin/env bash
# Run the Ruby demo. Requires Ruby + ffi gem (gem install ffi).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$ROOT/scripts/build-rust.sh" >/dev/null

if ! command -v ruby >/dev/null; then
    echo "[SKIP] ruby: ruby not installed" >&2
    exit 0
fi
if ! ruby -rffi -e 'nil' 2>/dev/null; then
    echo "[SKIP] ruby: ffi gem not installed (gem install ffi)" >&2
    exit 0
fi

WEAVEFFI_ROOT="$ROOT" ruby "$ROOT/demos/ruby/demo.rb"
