FROM ghcr.io/littlexia4-creator/nativelink-ubuntu:latest AS source
FROM python:3-slim
COPY --from=source /bin/nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
