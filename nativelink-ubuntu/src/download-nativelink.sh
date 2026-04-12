#!/bin/sh
set -eux

TAG="${NATIVELINK_TAG:-}"
REPO="tracemachina/nativelink"

# Resolve latest release tag if not provided.
if [ -z "$TAG" ]; then
  TAG=$(curl -sfL "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name)
fi
echo "Downloading nativelink:$TAG"

# Anonymous GHCR pull token.
TOKEN=$(curl -sf "https://ghcr.io/token?service=ghcr.io&scope=repository:$REPO:pull" | jq -r .token)

# Fetch the OCI manifest and extract the first layer digest.
DIGEST=$(curl -sfL \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.oci.image.manifest.v1+json" \
    "https://ghcr.io/v2/$REPO/manifests/$TAG" \
  | jq -r '.layers[0].digest')

# Download the layer and extract the nativelink binary.
mkdir -p /tmp/nl
curl -sfL \
    -H "Authorization: Bearer $TOKEN" \
    "https://ghcr.io/v2/$REPO/blobs/$DIGEST" \
  | tar xzf - -C /tmp/nl

find /tmp/nl -type f -name nativelink -path '*/bin/nativelink' \
  -exec install -m 0755 {} /bin/nativelink \;
rm -rf /tmp/nl
