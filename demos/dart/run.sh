#!/usr/bin/env bash
# Build & run the Dart demo. Sets WEAVEFFI_ROOT so the script can find
# the input asset and the absolute path to libweaveffi.dylib via cargo
# metadata, regardless of cwd.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$ROOT/scripts/build-rust.sh" >/dev/null

cd "$ROOT/demos/dart"
if [ ! -d .dart_tool ]; then
    dart pub get
fi

WEAVEFFI_ROOT="$ROOT" dart run bin/demo.dart
