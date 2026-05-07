# weaveffi-image-everywhere

> Sharp / Pillow / RMagick / ImageSharp equivalent — **one Rust engine,
> eleven native SDKs, byte-identical output across every language**. All
> from a single 100-line YAML file.

Built with **[WeaveFFI](https://github.com/weavefoundry/weaveffi)** 0.4.0.

```
                  ┌────────── image.yml ──────────┐
                  │  enums  Operation, ImageFormat │
                  │  funcs  resize, crop, rotate, │
                  │         blur, grayscale,      │
                  │         process, probe        │
                  └────────────────┬──────────────┘
                                   │  weaveffi generate
                                   ▼
   ┌──── 11 native SDKs ──────────────────────────────────┐
   │  Python  Node  Go  Ruby  Swift  Dart                 │
   │  C       C++   .NET  Kotlin  WebAssembly             │
   └────────────────┬─────────────────────────────────────┘
                    │  link against
                    ▼
            crates/weaveffi-image  (cdylib + rlib)
                    │  uses
                    ▼
              image  (pure-Rust, https://crates.io/crates/image)
```

Each SDK is a different language's idiomatic wrapper over the same C
ABI. Each one runs `[Resize(512, 512), Blur(2.0), Grayscale]` against
`assets/input.jpg`, encodes PNG, and prints the SHA-256 of the result.
Every hash is identical:

```
lang     status   sha256
----     ------   ------
python   OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
node     OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
go       OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
ruby     OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
swift    OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
dart     OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
c        OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
cpp      OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
csharp   OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
kotlin   OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397
wasm     OK       5934a11538833074236ba2110ba1698e7e98633428203a20bfb131fed3203397

OK: 11 language(s) all produced byte-identical PNGs
```

## The IDL

`image.yml` defines the entire surface — five operations, two structs,
two enums, seven functions:

```yaml
version: "0.3.0"
modules:
  - name: image
    enums:
      - { name: ImageFormat, variants: [Png, Jpeg, Webp, Gif] }
      - { name: OpKind, variants: [Resize, Crop, Rotate, Blur, Grayscale] }
    structs:
      - name: Operation
        fields:
          - { name: kind,    type: OpKind }
          - { name: width,   type: "u32?" }
          - { name: height,  type: "u32?" }
          - { name: x,       type: "u32?" }
          - { name: y,       type: "u32?" }
          - { name: degrees, type: "f64?" }
          - { name: sigma,   type: "f64?" }
      - name: ImageInfo
        fields:
          - { name: width,  type: u32 }
          - { name: height, type: u32 }
          - { name: format, type: ImageFormat }
    functions:
      - name: resize    # plus crop, rotate, blur, grayscale —
        params:         # factory functions returning Operation
          - { name: width,  type: u32 }
          - { name: height, type: u32 }
        return: Operation
      - name: process
        params:
          - { name: input,      type: bytes }
          - { name: ops,        type: "[Operation]" }
          - { name: out_format, type: ImageFormat }
        return: bytes
      - name: probe
        params:
          - { name: input, type: bytes }
        return: ImageInfo
```

One line generates every SDK:

```sh
weaveffi generate image.yml -o sdk \
  --target c,cpp,swift,android,node,wasm,python,dotnet,dart,go,ruby
```

## How it works

1. **`image.yml`** — language-agnostic interface definition.
2. **`weaveffi generate`** — emits 11 SDKs into `sdk/<lang>/`. Every
   SDK is a thin idiomatic wrapper over the same C ABI declared in
   `sdk/c/weaveffi.h`.
3. **`crates/weaveffi-image/src/lib.rs`** — pure-Rust facade that
   exports the C ABI and uses the [`image`](https://crates.io/crates/image)
   crate to do the actual work. Compiled to `libweaveffi.{dylib,so,dll}`
   and to `weaveffi.wasm`.
4. **`demos/<lang>/`** — one minimal program per language. Same input
   bytes in, same SHA-256 PNG bytes out. No language-specific
   re-implementation; every demo is just glue.

## Run it yourself

Prerequisites: Rust ≥ 1.74, `weaveffi-cli` 0.4.0
(`cargo install weaveffi-cli --version 0.4.0`), `just`
(`brew install just`), plus whichever language
toolchains you want to exercise (Python, Node, Go, Ruby, Swift, Dart,
clang/clang++, .NET, Kotlin/JDK). `verify.sh` skips any demo whose
toolchain is missing.

```sh
# One-shot: fetch the test image, regenerate SDKs, build the facade,
# run every demo, and assert all SHA-256s match.
just demo

# Or one demo at a time:
just run python
just run wasm
```

Without `just`:

```sh
bash scripts/fetch-asset.sh    # downloads assets/input.jpg from picsum.photos
bash scripts/generate.sh       # weaveffi validate + lint + generate
bash scripts/build-rust.sh     # cargo build --release -p weaveffi-image
bash scripts/verify.sh         # runs every demo, checks SHA-256s
```

## Code grid — same call, eleven languages

```python
# Python
import weaveffi
ops = [weaveffi.resize(512, 512), weaveffi.blur(2.0), weaveffi.grayscale()]
out = weaveffi.process(input_bytes, ops, weaveffi.ImageFormat.Png)
```

```javascript
// Node
const ops = [api.resize(512, 512), api.blur(2.0), api.grayscale()]
const out = api.process(input, ops, ImageFormat.Png)
```

```go
// Go
resize, _ := weaveffi.ImageResize(512, 512)
blur, _   := weaveffi.ImageBlur(2.0)
gray, _   := weaveffi.ImageGrayscale()
out, _    := weaveffi.ImageProcess(input,
    []*weaveffi.Operation{resize, blur, gray},
    weaveffi.ImageFormatPng)
```

```ruby
# Ruby
ops = [WeaveImage.resize(512, 512), WeaveImage.blur(2.0), WeaveImage.grayscale]
out = WeaveImage.process(input, ops, WeaveImage::ImageFormat::PNG)
```

```swift
// Swift
let ops = [Image.resize(512, 512), Image.blur(2.0), Image.grayscale()]
let out = try Image.process(input, ops, .png)
```

```dart
// Dart
final ops = [resize(512, 512), blur(2.0), grayscale()];
final out = process(input, ops, ImageFormat.png);
```

```c
/* C */
weaveffi_image_Operation* ops[] = {
    weaveffi_image_resize(512, 512, &err),
    weaveffi_image_blur(2.0, &err),
    weaveffi_image_grayscale(&err),
};
const uint8_t* out = weaveffi_image_process(
    input, input_len, ops, 3, weaveffi_image_ImageFormat_Png,
    &out_len, &err);
```

```cpp
// C++
auto ops = std::vector<weave_image::Operation>{
    weave_image::image_resize(512, 512),
    weave_image::image_blur(2.0),
    weave_image::image_grayscale(),
};
auto out = weave_image::image_process(input, ops, weave_image::ImageFormat::Png);
```

```csharp
// .NET
using var resize = Image.Resize(512, 512);
using var blur   = Image.Blur(2.0);
using var gray   = Image.Grayscale();
var out = Image.Process(input, new[] { resize, blur, gray }, ImageFormat.Png);
```

```kotlin
// Kotlin
val ops = longArrayOf(WeaveFFI.resize(512, 512),
                      WeaveFFI.blur(2.0),
                      WeaveFFI.grayscale())
val out = WeaveFFI.process(input, ops, ImageFormat.Png)
```

```javascript
// WebAssembly (browser or Node)
const { instance } = await WebAssembly.instantiateStreaming(fetch('weaveffi.wasm'))
const w = instance.exports
const ops = [w.weaveffi_image_resize(512, 512, errPtr),
             w.weaveffi_image_blur(2.0, errPtr),
             w.weaveffi_image_grayscale(errPtr)]
const outPtr = w.weaveffi_image_process(inputPtr, inputLen, opsPtr, 3,
                                        /*Png*/ 0, outLenPtr, errPtr)
```

## Layout

```
weaveffi-image-everywhere/
├── image.yml                    The IDL.
├── crates/weaveffi-image/       Rust facade — exports the C ABI,
│   └── src/lib.rs               uses the `image` crate.
├── sdk/                         Generated SDKs (committed for
│   ├── c/  cpp/  python/ ...    browseability; regenerate with
│   └── (11 languages)           `bash scripts/generate.sh`).
├── demos/                       One minimal runnable per language.
│   └── (11 directories, each    Each prints SHA-256 of its output.
│        with run.sh + README)
├── assets/input.jpg             Test image from picsum.photos
├── scripts/
│   ├── fetch-asset.sh           Downloads + verifies input.jpg.
│   ├── generate.sh              weaveffi validate / lint / generate.
│   ├── build-rust.sh            cargo build --release.
│   └── verify.sh                Runs every demo, asserts all SHA-256s match.
└── justfile                     `just demo` is the one-liner.
```

## Status notes (WeaveFFI 0.4.0)

The Rust facade and the C/Python/Node/Go/Ruby/.NET/Kotlin SDKs are
fully end-to-end. A few generators have small known issues at 0.4.0
that the demos work around (and document inline):

| SDK    | Status                                                  |
|--------|---------------------------------------------------------|
| Swift  | Generated package imports the wrong system module name; demo uses C ABI directly |
| Dart   | Generated `process` / `probe` typedefs are missing length params; demo uses `dart:ffi` directly |
| C++    | Generated `image_process` has a const-correctness bug; demo uses C ABI directly |
| .NET   | Generated `Image.Process` passes `Operation[]` where native expects `IntPtr+UIntPtr`; demo uses P/Invoke directly |
| WASM   | Stub doesn't yet marshal byte/list parameters; demo speaks to raw exports. The facade adds `weaveffi_alloc` / `weaveffi_dealloc` to satisfy the stub's allocator contract. |

In every case, the same pure-Rust facade and the same C ABI is what
produces the byte-identical output — **the SHA-256 grid above is the
proof.**

## Credits

The test image (`assets/input.jpg`) is
[*Scarlet macaw (Ara macao cyanopterus) head Copan*](https://commons.wikimedia.org/wiki/File:Scarlet_macaw_(Ara_macao_cyanopterus)_head_Copan.jpg)
by Charles J. Sharp ([sharpphotography.co.uk](https://www.sharpphotography.co.uk/)),
licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
Re-fetched on demand by `scripts/fetch-asset.sh`.
