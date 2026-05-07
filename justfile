# Run `just` (no args) to see the menu.
default:
    @just --list

# Fetch the test image from picsum.photos (cached on disk).
asset:
    bash scripts/fetch-asset.sh

# Validate the IDL and (re)generate every SDK into ./sdk/.
generate:
    bash scripts/generate.sh

# Build the Rust facade crate as a cdylib.
build:
    bash scripts/build-rust.sh

# Run all per-language demos and verify byte-identical SHA-256 output.
verify:
    bash scripts/verify.sh

# One-shot: asset + generate + build + verify.
demo: asset generate build verify

# Run a single language's demo (e.g. `just run python`).
run lang:
    bash demos/{{lang}}/run.sh

# Wipe build artifacts (cargo target dir, generated SDKs, demo outputs).
clean:
    cargo clean --manifest-path Cargo.toml
    rm -rf sdk
    find demos -name 'output.png' -delete
    find demos -name '.deps' -o -name '.build' -o -name 'build' -o -name 'node_modules' -o -name 'index.node' -o -name '.dart_tool' -o -name '.packages' -o -name 'pubspec.lock' -o -name '.swiftpm' -o -name 'bin' -o -name 'obj' -o -name '.gradle' -prune | xargs rm -rf || true
