FROM alpine:3 AS source
ARG NATIVELINK_TAG=""
RUN apk add --no-cache curl jq
COPY download-nativelink.sh /tmp/
RUN sh /tmp/download-nativelink.sh

FROM gcc:latest AS final
COPY --from=source /bin/nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
