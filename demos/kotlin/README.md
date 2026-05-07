# Kotlin demo

JVM Kotlin program that calls the WeaveFFI C ABI via JNA. Single file,
no Gradle, no Android NDK.

## Prerequisites

- JDK 11+
- `kotlinc` (`brew install kotlin`)

## Run

```sh
bash demos/kotlin/run.sh
```

The runner downloads `jna.jar` once into `demos/kotlin/.deps/` and
caches the compiled `Demo.jar` until `Demo.kt` changes.

## Note on the generated SDK

`sdk/android/` is the official generated target — Kotlin + a JNI shim
written in C, intended to be built by the Android NDK as part of an
Android Gradle module. This demo uses JNA instead so it can run as a
plain JVM program; the byte-identical SHA-256 still proves the same
WeaveFFI C ABI is what does the work end-to-end.

For Android: open `sdk/android/` in Android Studio, build the NDK
shim, and call `WeaveFFI.process(...)` from Kotlin as you would any
native library.
