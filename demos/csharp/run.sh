#!/usr/bin/env bash
# Build & run the .NET demo.
# Requires: dotnet 8 SDK (install via `brew install --cask dotnet-sdk` or
# from https://dotnet.microsoft.com/download).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB=$(bash "$ROOT/scripts/build-rust.sh" | tail -1)
LIB_DIR=$(dirname "$LIB")

if ! command -v dotnet >/dev/null; then
    echo "[SKIP] csharp: dotnet not installed (https://dotnet.microsoft.com/download)" >&2
    exit 0
fi

cd "$ROOT/demos/csharp"
WEAVEFFI_ROOT="$ROOT" \
DYLD_LIBRARY_PATH="$LIB_DIR:${DYLD_LIBRARY_PATH:-}" \
LD_LIBRARY_PATH="$LIB_DIR:${LD_LIBRARY_PATH:-}" \
dotnet run --project WeaveFFIImageDemo.csproj -c Release
