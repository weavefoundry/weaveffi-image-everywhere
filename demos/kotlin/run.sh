#!/usr/bin/env bash
# Build & run the Kotlin demo.
# Requires: kotlinc + JDK 11+. JNA jar is fetched from Maven Central if
# not already present in demos/kotlin/.deps.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB=$(bash "$ROOT/scripts/build-rust.sh" | tail -1)
LIB_DIR=$(dirname "$LIB")

if ! command -v kotlinc >/dev/null; then
    echo "[SKIP] kotlin: kotlinc not installed (brew install kotlin)" >&2
    exit 0
fi

cd "$ROOT/demos/kotlin"
mkdir -p .deps
JNA_VERSION="5.14.0"
JNA_JAR=".deps/jna-${JNA_VERSION}.jar"
if [ ! -f "$JNA_JAR" ]; then
    echo "==> fetching jna-${JNA_VERSION}.jar"
    curl -fsSL -o "$JNA_JAR" \
        "https://repo1.maven.org/maven2/net/java/dev/jna/jna/${JNA_VERSION}/jna-${JNA_VERSION}.jar"
fi

mkdir -p .build
if [ ! -f .build/Demo.jar ] || [ Demo.kt -nt .build/Demo.jar ]; then
    kotlinc -cp "$JNA_JAR" Demo.kt -include-runtime -d .build/Demo.jar
fi

WEAVEFFI_LIB="$LIB" WEAVEFFI_ROOT="$ROOT" \
    java -cp ".build/Demo.jar:$JNA_JAR" DemoKt
