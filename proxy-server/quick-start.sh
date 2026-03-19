CONTAINER_NAME="proxy-server"
docker rm "${CONTAINER_NAME}" -f
docker run -d --name "${CONTAINER_NAME}" -p 8443:8443/udp -p 2083:2083/tcp -p 2096:2096/tcp ghcr.io/littlexia4-creator/proxy-server
for i in $(seq 1 10); do
    STATE=$(docker inspect --format='{{.State.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "missing")
    if [[ "${STATE}" == "running" ]]; then
        break
    fi
    sleep 1
done
if [[ "${STATE}" != "running" ]]; then
    error "Container failed to start. Check logs: docker logs ${CONTAINER_NAME}"
fi
docker exec "${CONTAINER_NAME}" /usr/local/bin/proxy-verify.sh
