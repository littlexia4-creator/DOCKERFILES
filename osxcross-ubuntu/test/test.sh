#!/usr/bin/env bash
set -euo pipefail

export MSYS_NO_PATHCONV=1
IMAGE="${1:-ghcr.io/littlexia4-creator/osxcross-ubuntu:latest}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

docker run --rm -v "${SCRIPT_DIR}:/work" "$IMAGE" \
  o64-clang++ -v -o /work/hello /work/hello.cpp

file hello
