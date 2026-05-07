# Ruby demo

Runs the canonical pipeline through the [`ffi`](https://github.com/ffi/ffi)
gem and prints the SHA-256 of the resulting PNG.

## Prerequisites

- Ruby 2.7+
- `ffi` gem (`gem install ffi`)

## Run

```sh
bash demos/ruby/run.sh
```

The demo monkey-patches `FFI::Library.ffi_lib` so the bare name
`libweaveffi.dylib` resolves to an absolute path from
`cargo metadata` — necessary on macOS where SIP strips
`DYLD_LIBRARY_PATH` from `/usr/bin/ruby`.
