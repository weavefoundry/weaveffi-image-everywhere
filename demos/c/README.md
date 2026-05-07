# C demo

Plain C99 against the generated `sdk/c/weaveffi.h`. Uses CommonCrypto
for SHA-256 (macOS); on Linux swap the include for `<openssl/sha.h>`
and link `-lcrypto`.

## Prerequisites

- clang or gcc

## Run

```sh
bash demos/c/run.sh
```
