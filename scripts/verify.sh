#!/usr/bin/env bash
# Run every per-language demo, collect each SHA-256 line, print a grid,
# and exit non-zero if any hash differs from the others.
#
# Each demo's run.sh is responsible for installing toolchains it needs
# (or for skipping cleanly if the toolchain is missing). Skipped demos
# are marked SKIP in the grid and don't fail the verification.
#
# Pure POSIX-ish bash (no bash-4 associative arrays) so it runs on the
# stock /bin/bash that ships with macOS.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash "$ROOT/scripts/fetch-asset.sh" >/dev/null
bash "$ROOT/scripts/build-rust.sh" >/dev/null

# Languages run in pipeline order. Add new demos here.
LANGS="python node go ruby swift dart c cpp csharp kotlin wasm"

# Use parallel newline-delimited buffers (bash 3.2 compatible).
hashes_file=$(mktemp)
status_file=$(mktemp)
results_tsv=$(mktemp)
trap 'rm -f "$hashes_file" "$status_file" "$results_tsv"' EXIT

# Millisecond-precision wall clock. macOS BSD `date` doesn't take %N, and
# bash 3.2 lacks $EPOCHREALTIME, so we lean on python3 (already required
# elsewhere). Resolution is plenty for demo timings on the order of seconds.
now_ms() { python3 -c 'import time; print(int(time.time()*1000))'; }

file_size() { [ -f "$1" ] && stat -f%z "$1" 2>/dev/null || echo 0; }

for lang in $LANGS; do
    runner="$ROOT/demos/$lang/run.sh"
    output_png="$ROOT/demos/$lang/output.png"
    if [ ! -x "$runner" ]; then
        echo "MISSING" >> "$status_file"
        echo "-" >> "$hashes_file"
        printf '%s\tmissing\t\t0\t0\n' "$lang" >> "$results_tsv"
        continue
    fi
    start=$(now_ms)
    out=$(bash "$runner" 2>/tmp/weaveffi-$lang.stderr || true)
    runtime_ms=$(( $(now_ms) - start ))
    line=$(echo "$out" | grep -E "^$lang [0-9a-f]{64}$" | head -1 || true)
    out_size=$(file_size "$output_png")
    if [ -z "$line" ]; then
        if grep -q '\[SKIP\]' /tmp/weaveffi-$lang.stderr 2>/dev/null; then
            status="skip"
            echo "SKIP" >> "$status_file"
        else
            status="fail"
            echo "FAIL" >> "$status_file"
        fi
        echo "-" >> "$hashes_file"
        printf '%s\t%s\t\t%d\t%d\n' "$lang" "$status" "$runtime_ms" "$out_size" >> "$results_tsv"
        continue
    fi
    sha=$(echo "$line" | awk '{print $2}')
    echo "OK" >> "$status_file"
    echo "$sha" >> "$hashes_file"
    printf '%s\tok\t%s\t%d\t%d\n' "$lang" "$sha" "$runtime_ms" "$out_size" >> "$results_tsv"
done

# Canonical = most common non-empty hash.
canonical=$(grep -v '^-$' "$hashes_file" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

mismatches=0
ok_count=0

echo
printf "%-8s %-8s %s\n" "lang" "status" "sha256"
printf "%-8s %-8s %s\n" "----" "------" "------"
i=0
for lang in $LANGS; do
    i=$((i + 1))
    h=$(sed -n "${i}p" "$hashes_file")
    s=$(sed -n "${i}p" "$status_file")
    label=$s
    if [ "$s" = "OK" ]; then
        ok_count=$((ok_count + 1))
        if [ -n "$canonical" ] && [ "$h" != "$canonical" ]; then
            label="MISMATCH"
            mismatches=$((mismatches + 1))
        fi
    fi
    printf "%-8s %-8s %s\n" "$lang" "$label" "$h"
done

echo

# Emit machine-readable results next to the human grid (consumed by the
# Remotion composition that animates the language tiles).
python3 "$ROOT/scripts/_emit-results-json.py" \
    "$results_tsv" "${canonical:-}" "$ROOT" > "$ROOT/verify-results.json"
echo "[OK] wrote $ROOT/verify-results.json"

if [ "$mismatches" -gt 0 ]; then
    echo "FAIL: $mismatches demo(s) produced a different SHA-256 than the canonical $canonical" >&2
    exit 1
fi

if [ "$ok_count" -lt 1 ]; then
    echo "FAIL: no demos produced a hash" >&2
    exit 1
fi

echo "OK: $ok_count language(s) all produced byte-identical PNGs (sha256 $canonical)"
