# Swift demo

Swift Package that imports the WeaveFFI C ABI directly via a system
library module and runs the canonical pipeline.

## Prerequisites

- Swift 5.9+ (ships with Xcode 15 / macOS 14)

## Run

```sh
bash demos/swift/run.sh
```

The runner passes `-Xcc -I<sdk/c>` (header path), `-Xlinker -L<libdir>`,
and `-Xlinker -rpath` so `swift run` finds both `weaveffi.h` and
`libweaveffi.dylib`.

## Note on the generated SDK

`sdk/swift/` ships a high-level Swift wrapper, but in WeaveFFI 0.4.0 it
imports the wrong system library module name and the `process()`
helper is missing the `out_len` parameter. This demo bypasses the
wrapper for now. Once the upstream fixes land, replace
`Sources/CWeaveFFI/` with a dependency on the `WeaveImage` package and
call `Image.process(...)`.
