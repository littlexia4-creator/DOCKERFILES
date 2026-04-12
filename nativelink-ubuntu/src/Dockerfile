# CI can pass a specific tag (e.g. nix-hash from upstream logs) to skip the API lookup.
# Without it, the build resolves the latest release tag automatically.
ARG NATIVELINK_TAG=""

FROM python:3-slim AS downloader
ARG NATIVELINK_TAG
# Change CACHEBUST to invalidate the download cache (CI passes github.run_id).
ARG CACHEBUST
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends curl jq ca-certificates; \
    if [ -n "$NATIVELINK_TAG" ]; then \
      TAG="$NATIVELINK_TAG"; \
    else \
      TAG=$(curl -sfL https://api.github.com/repos/tracemachina/nativelink/releases/latest | jq -r .tag_name); \
    fi; \
    echo "Downloading nativelink:$TAG"; \
    TOKEN=$(curl -sf "https://ghcr.io/token?service=ghcr.io&scope=repository:tracemachina/nativelink:pull" | jq -r .token); \
    DIGEST=$(curl -sfL -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.oci.image.manifest.v1+json" \
        "https://ghcr.io/v2/tracemachina/nativelink/manifests/$TAG" \
      | jq -r '.layers[0].digest'); \
    mkdir /tmp/nl; \
    curl -sfL -H "Authorization: Bearer $TOKEN" \
        "https://ghcr.io/v2/tracemachina/nativelink/blobs/$DIGEST" \
      | tar xzf - -C /tmp/nl; \
    find /tmp/nl -type f -name nativelink -path '*/bin/nativelink' \
      -exec install -m 0755 {} /bin/nativelink \; ; \
    rm -rf /tmp/nl

FROM python:3-slim
COPY --from=downloader /bin/nativelink /bin/nativelink
ENTRYPOINT ["/bin/nativelink"]
