# Python demo

Runs the canonical pipeline through the auto-generated `ctypes`
bindings and prints the SHA-256 of the resulting PNG.

## Prerequisites

- Python 3.9+

## Run

```sh
bash demos/python/run.sh
```

The demo monkey-patches `ctypes.CDLL` so the SDK's bare-name lookup of
`libweaveffi.dylib` resolves to the absolute cargo target path —
necessary on macOS, where SIP strips `DYLD_LIBRARY_PATH` from the
system Python binary.
