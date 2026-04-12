ARG NATIVELINK_TAG=""

FROM alpine:3 AS downloader
ARG NATIVELINK_TAG
ARG CACHEBUST
RUN apk add --no-cache curl jq
COPY download-nativelink.sh /tmp/
RUN sh /tmp/download-nativelink.sh

FROM python:3-slim
COPY --from=downloader /bin/nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
