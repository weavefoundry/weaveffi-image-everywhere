# Node demo

Runs the canonical pipeline through the WeaveFFI N-API addon and prints
the SHA-256 of the resulting PNG.

## Prerequisites

- Node 18+
- A C toolchain for `node-gyp` (Xcode CLT on macOS)

## Run

```sh
bash demos/node/run.sh
```

The first run executes `setup.sh`, which fetches npm deps and builds
`sdk/node/index.node` against `libweaveffi.dylib`. Subsequent runs reuse
the existing addon.
