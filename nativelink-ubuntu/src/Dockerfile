ARG NATIVELINK_TAG=4mcy7swhxa5xp0mpjqk7pbq6il8y9l9a
FROM ghcr.io/tracemachina/nativelink:${NATIVELINK_TAG} AS source

# Resolve the nix-store path at build time — upstream bakes nativelink at
# /nix/store/<hash>-nativelink-.../bin/nativelink where <hash> changes every release.
FROM alpine:3 AS resolver
COPY --from=source /nix /nix
RUN set -eux; \
    bin="$(find /nix/store -type f -path '*/bin/nativelink' | head -n1)"; \
    [ -n "$bin" ] || { echo "nativelink binary not found in /nix/store" >&2; exit 1; }; \
    install -m 0755 "$bin" /nativelink

FROM python:3-slim AS final
COPY --from=resolver /nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
