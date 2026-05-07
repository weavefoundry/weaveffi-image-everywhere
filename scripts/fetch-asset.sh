#!/usr/bin/env bash
# Download the test image used by every demo.
#
# Source: "Scarlet macaw (Ara macao cyanopterus) head Copan" by Charles J.
# Sharp (https://commons.wikimedia.org/wiki/File:Scarlet_macaw_(Ara_macao_cyanopterus)_head_Copan.jpg),
# licensed CC BY-SA 4.0. A 1024-wide head close-up that's vivid enough to make
# the [Resize -> Blur -> Grayscale] pipeline visibly obvious.
#
# We sha-256 the result against a known-good hash so we'd notice immediately
# if the upstream image ever changed. Wikimedia rejects requests without a
# User-Agent.
#
# Skip if the asset is already present and matches the expected hash.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSET="$ROOT/assets/input.jpg"
URL="https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Scarlet_macaw_%28Ara_macao_cyanopterus%29_head_Copan.jpg/1024px-Scarlet_macaw_%28Ara_macao_cyanopterus%29_head_Copan.jpg"
EXPECTED_SHA="fc046138c685947efd4aa9eaa53c60deaa563ebcf20cfaa46b5ecab571ee603a"
USER_AGENT="weaveffi-image-everywhere/0.1 (https://github.com/weavefoundry/weaveffi)"

mkdir -p "$ROOT/assets"

verify() {
    if [ ! -f "$ASSET" ]; then
        return 1
    fi
    local actual
    actual=$(shasum -a 256 "$ASSET" | awk '{print $1}')
    [ "$actual" = "$EXPECTED_SHA" ]
}

if verify; then
    echo "[OK] $ASSET ($(stat -f%z "$ASSET") bytes, sha256 verified)"
    exit 0
fi

echo "==> downloading $URL"
curl --fail --silent --show-error --location \
    -A "$USER_AGENT" \
    --output "$ASSET" "$URL"

if ! verify; then
    actual=$(shasum -a 256 "$ASSET" | awk '{print $1}')
    echo "ERROR: downloaded asset sha256 mismatch" >&2
    echo "  expected: $EXPECTED_SHA" >&2
    echo "  actual:   $actual" >&2
    rm -f "$ASSET"
    exit 1
fi

echo "[OK] $ASSET fetched and verified ($(stat -f%z "$ASSET") bytes)"
