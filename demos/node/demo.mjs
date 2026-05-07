// Node demo for weaveffi-image.
//
// Loads the auto-generated N-API addon from sdk/node, runs the canonical
// pipeline, writes output.png next to this script, prints the SHA-256.
import { createHash } from 'node:crypto'
import { readFileSync, writeFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(HERE, '..', '..')

// The generated SDK exports the IDL functions; enum integer values are
// type-only (TS ambient enums) so we redeclare the runtime values here.
// They mirror the IDL and would compile-time check via types.d.ts.
const ImageFormat = { Png: 0, Jpeg: 1, Webp: 2, Gif: 3 }

const require = createRequire(import.meta.url)
const api = require(resolve(ROOT, 'sdk/node/index.js'))

const input = readFileSync(resolve(ROOT, 'assets/input.jpg'))

const info = api.probe(input)
// `probe()` returns a struct handle (int64), not a plain object. The
// generated TS types expose accessors but the addon currently surfaces
// the raw pointer. The Rust facade keeps the struct alive until probe's
// caller drops it; at process exit the heap is reclaimed regardless.
process.stderr.write(`node:   input handle ${info}\n`)

const ops = [
  api.resize(512, 512),
  api.blur(2.0),
  api.grayscale(),
]
const output = api.process(input, ops, ImageFormat.Png)

const outputPath = resolve(HERE, 'output.png')
writeFileSync(outputPath, output)
const digest = createHash('sha256').update(output).digest('hex')
console.log(`node ${digest}`)
process.stderr.write(`node:   wrote  demos/node/output.png (${output.length} bytes)\n`)
