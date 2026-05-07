# Go demo

Runs the canonical pipeline through CGo bindings and prints the SHA-256
of the resulting PNG.

## Prerequisites

- Go 1.21+
- A C toolchain for cgo (Xcode CLT on macOS)

## Run

```sh
bash demos/go/run.sh
```

`setup.sh` exports the `CGO_CFLAGS` / `CGO_LDFLAGS` needed to find
`weaveffi.h` in `sdk/c/` and `libweaveffi.dylib` in the cargo target dir
(via an embedded `-rpath`).
