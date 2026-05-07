# C++ demo

C++17 against the WeaveFFI C ABI (declared `extern "C"` from
`sdk/c/weaveffi.h`). Uses CommonCrypto for SHA-256 on macOS.

## Prerequisites

- clang++ or g++ with C++17

## Run

```sh
bash demos/cpp/run.sh
```

## Note on the generated SDK

`sdk/cpp/weaveffi.hpp` ships a header-only `weave_image` namespace, but
in WeaveFFI 0.4.0 the `image_process` helper has a const-correctness
bug that prevents it from compiling. This demo uses the C ABI directly;
once the fix lands, it can switch to:

```cpp
auto ops = std::vector<weave_image::Operation>{};
ops.push_back(weave_image::image_resize(512, 512));
ops.push_back(weave_image::image_blur(2.0));
ops.push_back(weave_image::image_grayscale());
auto out = weave_image::image_process(input, ops, weave_image::ImageFormat::Png);
```
