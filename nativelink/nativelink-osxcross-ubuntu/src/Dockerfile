FROM ghcr.io/littlexia4-creator/nativelink-ubuntu:latest AS source
FROM ghcr.io/littlexia4-creator/osxcross-ubuntu
COPY --link --from=source /bin/nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
