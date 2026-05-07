"""Python demo for weaveffi-image.

Loads the same Rust facade every other language demo loads, runs the
canonical pipeline, writes output.png next to this script, and prints
the SHA-256 of the output. Other demos do the same; verify.sh asserts
every line's hash is identical.
"""

import ctypes
import hashlib
import os
import platform
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SDK_PATH = ROOT / "sdk" / "python"
sys.path.insert(0, str(SDK_PATH))


def _resolve_lib() -> str:
    """Return an absolute path to libweaveffi.{dylib,so,dll}.

    macOS SIP strips DYLD_LIBRARY_PATH from system Pythons, so the
    generated SDK's bare `CDLL('libweaveffi.dylib')` lookup fails for
    locally-built libraries. We resolve the path explicitly here from
    the `WEAVEFFI_LIB` env var (set by verify.sh / justfile) or from
    `cargo metadata`, then patch ctypes.CDLL so the SDK call lands on
    the real file.
    """
    if env := os.environ.get("WEAVEFFI_LIB"):
        return env
    ext = {"Darwin": "dylib", "Windows": "dll"}.get(platform.system(), "so")
    out = subprocess.check_output(
        ["cargo", "metadata", "--no-deps", "--format-version", "1"],
        cwd=ROOT,
    )
    import json

    target_dir = json.loads(out)["target_directory"]
    return f"{target_dir}/release/libweaveffi.{ext}"


_LIB_PATH = _resolve_lib()
if not Path(_LIB_PATH).exists():
    sys.stderr.write(
        f"libweaveffi not found at {_LIB_PATH}. "
        "Run `bash scripts/build-rust.sh` first.\n"
    )
    sys.exit(1)

# Patch ctypes.CDLL so the generated SDK's bare-name lookup resolves.
_orig_cdll = ctypes.CDLL
_BARE_NAMES = {"libweaveffi.dylib", "libweaveffi.so", "weaveffi.dll"}


def _patched_cdll(name, *a, **kw):
    if name in _BARE_NAMES:
        return _orig_cdll(_LIB_PATH, *a, **kw)
    return _orig_cdll(name, *a, **kw)


ctypes.CDLL = _patched_cdll  # type: ignore[assignment]

from weaveffi import (  # noqa: E402  (deferred until CDLL is patched)
    ImageFormat,
    blur,
    grayscale,
    process,
    probe,
    resize,
)


def main() -> int:
    input_path = ROOT / "assets" / "input.jpg"
    output_path = HERE / "output.png"

    input_bytes = input_path.read_bytes()

    info = probe(input_bytes)
    sys.stderr.write(
        f"python: input  {info.width}x{info.height} ({info.format.name})\n"
    )

    pipeline = [
        resize(512, 512),
        blur(2.0),
        grayscale(),
    ]
    output_bytes = process(input_bytes, pipeline, ImageFormat.Png)

    output_path.write_bytes(output_bytes)
    digest = hashlib.sha256(output_bytes).hexdigest()
    print(f"python {digest}")
    sys.stderr.write(
        f"python: wrote  {output_path.relative_to(ROOT)} ({len(output_bytes)} bytes)\n"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
