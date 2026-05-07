# Dart demo

Hand-rolled `dart:ffi` bindings that drive the canonical pipeline.

## Prerequisites

- Dart 3.0+

## Run

```sh
bash demos/dart/run.sh
```

## Note on the generated SDK

`sdk/dart/lib/weaveffi.dart` declares `process()` and `probe()` with the
wrong native signatures (missing `size_t input_len` / `size_t* out_len`)
and does the optional-field accessors as direct values rather than
pointers. Once those upstream fixes land, this demo can switch to:

```dart
import 'package:weave_image/weaveffi.dart' as wi;

final ops = [wi.resize(512, 512), wi.blur(2.0), wi.grayscale()];
final out = wi.process(input, ops, wi.ImageFormat.png);
```
