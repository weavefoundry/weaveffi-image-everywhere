#!/usr/bin/env bash
# Build the weaveffi-image facade as a release-mode cdylib.
#
# Prints the absolute path to the produced library on stdout (last line)
# so callers can pipe it into env vars (e.g. `LIB=$(scripts/build-rust.sh | tail -1)`).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

case "$(uname -s)" in
    Darwin) EXT=dylib ;;
    Linux)  EXT=so ;;
    MINGW*|MSYS*|CYGWIN*) EXT=dll ;;
    *)      EXT=so ;;
esac

# Build the facade. RUSTFLAGS picked to deny warnings and to keep the
# release lib reasonably small.
echo "==> cargo build --release -p weaveffi-image" >&2
RUSTFLAGS="${RUSTFLAGS:--D warnings}" cargo build --release -p weaveffi-image >&2

# `cargo metadata` returns the canonical target_directory regardless of
# whether the user has CARGO_TARGET_DIR set or some other override.
TARGET_DIR=$(cargo metadata --no-deps --format-version 1 \
    | python3 -c "import sys,json;print(json.load(sys.stdin)['target_directory'])")

LIB="$TARGET_DIR/release/libweaveffi.$EXT"

if [ ! -f "$LIB" ]; then
    echo "ERROR: expected library not found at $LIB" >&2
    exit 1
fi

echo "[OK] $LIB ($(stat -f%z "$LIB" 2>/dev/null || stat -c%s "$LIB") bytes)" >&2
echo "$LIB"
