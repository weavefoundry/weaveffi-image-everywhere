# WebAssembly demo

Loads `weaveffi.wasm` (built from the same Rust facade for the
`wasm32-unknown-unknown` target) into Node's WebAssembly runtime and
drives the canonical pipeline through linear memory.

## Prerequisites

- Rust + `wasm32-unknown-unknown` target
  (`rustup target add wasm32-unknown-unknown`)
- Node 18+

## Run

```sh
bash demos/wasm/run.sh
```

The runner builds `target/wasm32-unknown-unknown/release/weaveffi.wasm`
and the demo loads it directly. Runs in Node, but the same `.wasm` is
loadable in any browser — instantiate, copy the input bytes into linear
memory, call `weaveffi_image_process`, and read the output bytes back.

## Note on the generated SDK

`sdk/wasm/weaveffi_wasm.js` is a minimal stub that uses an alloc helper
that wasn't in the WeaveFFI 0.4.0 facade by default; this project
exports `weaveffi_alloc` / `weaveffi_dealloc` from `crates/weaveffi-image/src/lib.rs`
to satisfy that contract. The stub also doesn't yet marshal byte/list
parameters across the WASM boundary, so this demo speaks to the raw
exports.
