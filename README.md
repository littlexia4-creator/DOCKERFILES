# DOCKERFILES

A collection of Dockerfiles for quick server deployment.

## proxy-server

Deploys **Hysteria2** (primary) + **VLESS+Reality** (backup) dual-protocol proxy with subscription service.

### Ports

| Port | Protocol | Service |
|------|----------|---------|
| 8443 | UDP | Hysteria2 |
| 2083 | TCP | VLESS+Reality |
| 2096 | TCP | Subscription service |

### Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/littlexia4-creator/DOCKERFILES/refs/heads/main/proxy-server/quick-start.sh | bash
```

### Subscription

After deployment, run verify script to get subscription URLs with QR codes:

```bash
docker exec proxy-server /usr/local/bin/proxy-verify.sh
```

| Client | Subscription URL |
|--------|------------------|
| shadowrocket / ClashX.Meta | `http://<IP>:2096/<token>/clash.yaml` |
| v2rayN | `http://<IP>:2096/<token>/v2rayn.txt` |
| v2rayN (SSL) | `https://tinyurl.com/<alias>` |

## nativelink-ubuntu

Packages the [nativelink](https://github.com/TraceMachina/nativelink) remote-execution / Content-Addressable Storage (CAS) server on a `python:3-slim` base, so Python-based remote workers and tooling can run in the same container as the server.
The `nativelink` binary is lifted out of the upstream `ghcr.io/tracemachina/nativelink` image and dropped at `/bin/nativelink` as the entrypoint.

### Image

```
ghcr.io/littlexia4-creator/nativelink-ubuntu:latest
```

Only `linux/amd64` is published — the upstream binary is `x86_64-unknown-linux-musl`.

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/littlexia4-creator/DOCKERFILES/refs/heads/main/nativelink-ubuntu/install.sh | bash
```

Installs Docker if missing and pulls the image. The container is not started — run it with your own nativelink config when you're ready.


---

## Reference: image pipelines

| Image | Source path | Platforms | Trigger paths |
|-------|-------------|-----------|---------------|
| `ghcr.io/littlexia4-creator/proxy-server` | `proxy-server/src` | `linux/amd64,linux/arm64` | `proxy-server/src/**` |
| `ghcr.io/littlexia4-creator/nativelink-ubuntu` | `nativelink-ubuntu/src` | `linux/amd64` | `nativelink-ubuntu/src/**` |

Both are tagged `latest` on default-branch pushes and by short SHA on every push, via `docker/metadata-action@v5`.
