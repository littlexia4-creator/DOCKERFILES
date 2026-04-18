FROM alpine:3 AS nativelink-source
ARG NATIVELINK_TAG=""
RUN apk add --no-cache curl jq
COPY download-nativelink.sh /tmp/
RUN sh /tmp/download-nativelink.sh

FROM ghcr.io/littlexia4-creator/osxcross-ubuntu
COPY --link --from=nativelink-source  /bin/nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
