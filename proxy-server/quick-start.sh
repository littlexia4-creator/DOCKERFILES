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

# Image entrypoint cannot auto-detect the IP (no `ip` command in image)
SERVER_IP="${SERVER_IP:-$(curl -fsSL --max-time 5 https://ifconfig.me || curl -fsSL --max-time 5 https://ipinfo.io/ip)}"
if [ -z "${SERVER_IP}" ]; then
    echo "Error: Unable to detect public IP. Set SERVER_IP environment variable."
    exit 1
fi
echo "Info: Using SERVER_IP=${SERVER_IP}"

docker rm "${CONTAINER_NAME}" -f 2>/dev/null
docker pull "${IMAGE}"
docker run -d --name "${CONTAINER_NAME}" --restart unless-stopped \
    -e SERVER_IP="${SERVER_IP}" \
    -v proxy-www:/var/www -v proxy-creds:/etc/proxy \
    -p 8443:8443/udp -p 2083:2083/tcp -p 2096:2096/tcp \
    "${IMAGE}"

# Self-heal: if docker0 lost its gateway IP, containers become unreachable
GW=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' "${CONTAINER_NAME}")
SUBNET=$(docker network inspect bridge -f '{{(index .IPAM.Config 0).Subnet}}')
if [ -n "${GW}" ] && [ -n "${SUBNET}" ] && ! ip -4 -o addr show docker0 | grep -qw "${GW}"; then
    echo "Info: docker0 missing gateway ${GW}, restoring..."
    ip addr add "${GW}/${SUBNET#*/}" dev docker0
fi

docker exec "${CONTAINER_NAME}" /usr/local/bin/proxy-verify.sh
