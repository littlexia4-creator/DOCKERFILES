FROM ghcr.io/littlexia4-creator/nativelink-ubuntu:latest AS source
FROM gcc:latest AS final
COPY --from=source /bin/nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
