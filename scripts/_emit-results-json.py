#!/usr/bin/env python3
"""Emit verify-results.json from the TSV that scripts/verify.sh writes.

Called as: _emit-results-json.py <tsv> <canonical_sha> <repo_root> > out.json

The TSV format (one row per language, tab-separated):
    lang  status  sha  runtime_ms  output_size_bytes

`status` is one of: ok, skip, fail, missing.
`sha` is the SHA-256 hex string for ok demos, empty otherwise.
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import time


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2
    tsv_path, canonical_arg, root = sys.argv[1:]
    canonical = canonical_arg or None

    input_path = os.path.join(root, "assets/input.jpg")
    input_sha: str | None = None
    input_size: int | None = None
    if os.path.exists(input_path):
        with open(input_path, "rb") as f:
            data = f.read()
        input_sha = hashlib.sha256(data).hexdigest()
        input_size = len(data)

    demos: list[dict] = []
    ok_count = 0
    match_count = 0
    canonical_output_size: int | None = None

    with open(tsv_path) as f:
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            lang, status, sha, runtime_ms, out_size = line.split("\t")
            runtime = int(runtime_ms) if runtime_ms else 0
            size = int(out_size) if out_size else 0
            sha = sha or None

            matches = bool(canonical and sha == canonical)
            if status == "ok":
                ok_count += 1
                if matches:
                    match_count += 1
                    if canonical_output_size is None:
                        canonical_output_size = size
                elif canonical:
                    status = "mismatch"

            demos.append({
                "lang": lang,
                "status": status,
                "sha": sha,
                "runtime_ms": runtime,
                "matches_canonical": matches,
                "output_png": f"demos/{lang}/output.png" if size > 0 else None,
                "output_png_size_bytes": size or None,
            })

    result = {
        "schema_version": 1,
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "canonical_sha256": canonical,
        "all_match": ok_count > 0 and match_count == ok_count,
        "demo_count": len(demos),
        "ok_count": ok_count,
        "match_count": match_count,
        "input": {
            "path": "assets/input.jpg",
            "sha256": input_sha,
            "size_bytes": input_size,
        },
        "canonical_output_size_bytes": canonical_output_size,
        "demos": demos,
    }
    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
