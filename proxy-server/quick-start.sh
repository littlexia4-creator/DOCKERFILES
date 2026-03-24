#!/bin/bash

CONTAINER_NAME="proxy-server"
IMAGE="ghcr.io/littlexia4-creator/proxy-server:latest"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Info: Docker is not installed. Attempting to install Docker..."
    curl -fsSL https://raw.githubusercontent.com/littlexia4-creator/quick-install-hub/refs/heads/main/ubuntu-docker-install-start.sh | bash
fi

if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running. Please start Docker manually and try again."
    exit 1
fi

docker rm "${CONTAINER_NAME}" -f 2>/dev/null
docker pull "${IMAGE}"
docker run -d --name "${CONTAINER_NAME}" -p 8443:8443/udp -p 2083:2083/tcp -p 2096:2096/tcp "${IMAGE}"
sleep 3
docker exec "${CONTAINER_NAME}" /usr/local/bin/proxy-verify.sh
