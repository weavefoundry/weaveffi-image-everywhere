// WASM demo for weaveffi-image.
//
// Loads weaveffi.wasm (built via `cargo build --target
// wasm32-unknown-unknown --release`) into Node's WebAssembly runtime
// and drives the same canonical pipeline through the C ABI exposed
// over linear memory. The generated SDK at sdk/wasm/weaveffi_wasm.js
// has known issues handling byte/list parameters in WeaveFFI 0.4.0,
// so this demo talks to the raw exports.
import { createHash } from 'node:crypto'
import { execSync } from 'node:child_process'
import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(HERE, '..', '..')

function targetDir() {
    const meta = JSON.parse(execSync('cargo metadata --no-deps --format-version=1', { cwd: ROOT, encoding: 'utf8' }))
    return meta.target_directory
}

const wasmPath = resolve(targetDir(), 'wasm32-unknown-unknown/release/weaveffi.wasm')
const bytes = readFileSync(wasmPath)
const { instance } = await WebAssembly.instantiate(bytes, {})
const w = instance.exports

const WASM_PAGE = 64 * 1024
function ensureMem(extra) {
    const need = extra
    const cur = w.memory.buffer.byteLength
    if (need > cur) {
        const grow = Math.ceil((need - cur) / WASM_PAGE)
        w.memory.grow(grow)
    }
}

function alloc(n) {
    return w.weaveffi_alloc(n)
}
function dealloc(ptr, n) {
    w.weaveffi_dealloc(ptr, n)
}

function writeBytes(arr) {
    const ptr = alloc(arr.length)
    new Uint8Array(w.memory.buffer, ptr, arr.length).set(arr)
    return ptr
}

function readBytes(ptr, len) {
    return new Uint8Array(new Uint8Array(w.memory.buffer, ptr, len))
}

function readErr(errPtr) {
    const view = new DataView(w.memory.buffer, errPtr, 8)
    const code = view.getInt32(0, true)
    if (code === 0) return null
    const msgPtr = view.getUint32(4, true)
    let end = msgPtr
    const mem = new Uint8Array(w.memory.buffer)
    while (mem[end] !== 0) end++
    const msg = new TextDecoder().decode(mem.subarray(msgPtr, end))
    w.weaveffi_error_clear(errPtr)
    return { code, msg }
}

function check(errPtr, what) {
    const e = readErr(errPtr)
    if (e) {
        process.stderr.write(`wasm:   ${what} failed: ${e.msg} (code ${e.code})\n`)
        process.exit(1)
    }
}

const errPtr = alloc(8)
const input = readFileSync(resolve(ROOT, 'assets/input.jpg'))
const inputPtr = writeBytes(input)

const info = w.weaveffi_image_probe(inputPtr, input.length, errPtr)
check(errPtr, 'probe')
process.stderr.write(`wasm:   input  ${w.weaveffi_image_ImageInfo_get_width(info)}x${w.weaveffi_image_ImageInfo_get_height(info)}\n`)
w.weaveffi_image_ImageInfo_destroy(info)

const resize = w.weaveffi_image_resize(512, 512, errPtr); check(errPtr, 'resize')
const blur   = w.weaveffi_image_blur(2.0, errPtr);        check(errPtr, 'blur')
const gray   = w.weaveffi_image_grayscale(errPtr);        check(errPtr, 'grayscale')

// Build an i32[3] array of operation pointers in linear memory; the
// C ABI takes `Operation* const* ops, size_t ops_len`.
const opsPtr = alloc(4 * 3)
const opsView = new Uint32Array(w.memory.buffer, opsPtr, 3)
opsView[0] = resize
opsView[1] = blur
opsView[2] = gray

const outLenPtr = alloc(4)
const outPtr = w.weaveffi_image_process(
    inputPtr, input.length,
    opsPtr, 3,
    0,
    outLenPtr,
    errPtr,
)
check(errPtr, 'process')
const outLen = new DataView(w.memory.buffer, outLenPtr, 4).getUint32(0, true)
const outBytes = readBytes(outPtr, outLen)

w.weaveffi_free_bytes(outPtr, outLen)
w.weaveffi_image_Operation_destroy(resize)
w.weaveffi_image_Operation_destroy(blur)
w.weaveffi_image_Operation_destroy(gray)
dealloc(opsPtr, 4 * 3)
dealloc(outLenPtr, 4)
dealloc(inputPtr, input.length)
dealloc(errPtr, 8)

writeFileSync(resolve(HERE, 'output.png'), outBytes)
const digest = createHash('sha256').update(outBytes).digest('hex')
console.log(`wasm ${digest}`)
process.stderr.write(`wasm:   wrote  demos/wasm/output.png (${outBytes.length} bytes)\n`)
