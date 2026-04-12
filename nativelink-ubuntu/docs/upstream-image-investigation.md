# tmp.md

## Investigating upstream base images

`nativelink-ubuntu` rebases an upstream image (`ghcr.io/tracemachina/nativelink`). When the `FROM` breaks, the root cause is usually "that tag doesn't exist" or "the binary moved in the image".

### List tags anonymously (public images)

The GHCR OCI endpoint requires a bearer token, but public images mint one anonymously:

```bash
TOKEN=$(curl -sf "https://ghcr.io/token?service=ghcr.io&scope=repository:tracemachina/nativelink:pull" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')

curl -sf -D /tmp/hdrs -H "Authorization: Bearer $TOKEN" \
    "https://ghcr.io/v2/tracemachina/nativelink/tags/list?n=1000"
```

Pagination: check `/tmp/hdrs` for a `link: </v2/...?last=...&n=1000>; rel="next"` header and follow it until gone.

### Prefer the GitHub Releases API for "what version is latest"

The registry `tags/list` has no timestamps, and GitHub's Packages API requires `read:packages` scope. For projects that cut GitHub releases, use the unauthenticated releases endpoint instead:

```bash
curl -sfL https://api.github.com/repos/tracemachina/nativelink/releases/latest | jq -r .tag_name
```

This is exactly what `docker-build.yml`'s `Resolve latest nativelink release tag` step does — it injects the resolved tag into the image via `build-args: NATIVELINK_TAG=…`, so the Dockerfile's `FROM ghcr.io/tracemachina/nativelink:${NATIVELINK_TAG}` tracks upstream without manual bumps.

### Inspect an upstream image's layout

```bash
# entrypoint (revealing nix-store or /bin path)
sudo docker inspect ghcr.io/tracemachina/nativelink:v1.0.0 \
    --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}'

# file listing — fails if the image is distroless (no shell)
sudo docker run --rm --entrypoint sh <image> -c 'find / -name foo'
```
