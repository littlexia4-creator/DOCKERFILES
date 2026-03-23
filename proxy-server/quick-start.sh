CONTAINER_NAME="proxy-server"
IMAGE="ghcr.io/littlexia4-creator/proxy-server:latest"

docker rm "${CONTAINER_NAME}" -f 2>/dev/null
docker pull "${IMAGE}"
docker run -d --name "${CONTAINER_NAME}" -p 8443:8443/udp -p 2083:2083/tcp -p 2096:2096/tcp "${IMAGE}"
sleep 3
docker exec "${CONTAINER_NAME}" /usr/local/bin/proxy-verify.sh
