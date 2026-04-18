#!/bin/bash

IMAGE="ghcr.io/littlexia4-creator/nativelink-python:latest"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Info: Docker is not installed. Attempting to install Docker..."
    curl -fsSL https://raw.githubusercontent.com/littlexia4-creator/quick-install-hub/refs/heads/main/ubuntu-docker-install-start.sh | bash
fi

if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running. Please start Docker manually and try again."
    exit 1
fi

docker pull "${IMAGE}"
