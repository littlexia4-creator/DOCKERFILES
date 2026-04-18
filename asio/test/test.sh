#!/bin/sh
set -eu

IMAGE="ghcr.io/littlexia4-creator/asio:latest"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Pulling image ==="

docker pull "$IMAGE"

echo "=== Building and running hello.cpp ==="

rm -f "$SRC_DIR/hello"

MSYS_NO_PATHCONV=1 docker run --rm \
    -v "$SRC_DIR:/src" \
    "$IMAGE" \
    g++ -std=c++17 -o /src/hello /src/hello.cpp

MSYS_NO_PATHCONV=1 docker run --rm \
    -v "$SRC_DIR:/src" \
    "$IMAGE" \
    /src/hello

