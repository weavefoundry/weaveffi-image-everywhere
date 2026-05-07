#!/usr/bin/env bash
# Build the generated N-API addon in sdk/node and link it against
# libweaveffi.dylib. Re-run whenever the IDL or facade changes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB=$(bash "$ROOT/scripts/build-rust.sh" | tail -1)
LIB_DIR=$(dirname "$LIB")

cd "$ROOT/sdk/node"

# node-gyp needs to find both the C header (../c) and libweaveffi at link
# and runtime. -L tells the linker; -Wl,-rpath embeds a runtime search
# path into the .node addon so we don't need DYLD_LIBRARY_PATH at exec.
case "$(uname -s)" in
    Darwin)
        export LDFLAGS="-L${LIB_DIR} -Wl,-rpath,${LIB_DIR}"
        ;;
    *)
        export LDFLAGS="-L${LIB_DIR} -Wl,-rpath,${LIB_DIR}"
        ;;
esac
export LIBRARY_PATH="$LIB_DIR:${LIBRARY_PATH:-}"

# Some npm globals reject root-mode; use --no-audit / --no-fund for less noise.
if [ ! -f package-lock.json ]; then
    npm install --no-audit --no-fund --loglevel=error 2>&1 | tail -20
else
    npm install --no-audit --no-fund --loglevel=error 2>&1 | tail -20
fi

if [ ! -f build/Release/weaveffi.node ]; then
    echo "[FAIL] sdk/node addon failed to build (build/Release/weaveffi.node missing)" >&2
    exit 1
fi

# index.js requires `./index.node`. node-gyp drops the binary at
# build/Release/weaveffi.node — symlink so index.js can find it.
ln -sf build/Release/weaveffi.node index.node
echo "[OK] sdk/node/index.node ready"
