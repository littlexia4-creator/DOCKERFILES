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

## nativelink-python

Packages the [nativelink](https://github.com/TraceMachina/nativelink) remote-execution / Content-Addressable Storage (CAS) server on a `python:3-slim` base, so Python-based remote workers and tooling can run in the same container as the server.
The `nativelink` binary is lifted from the upstream `ghcr.io/tracemachina/nativelink` image and dropped at `/bin/nativelink` as the entrypoint.

### Image

```
ghcr.io/littlexia4-creator/nativelink-python:latest
```

Only `linux/amd64` is published — the upstream binary is `x86_64-unknown-linux-musl`.

## nativelink-gcc

Same as nativelink-python but on a `gcc:latest` base, providing a full C/C++ build toolchain alongside the nativelink server. Useful for remote-execution workers that need to compile native code.

### Image

```
ghcr.io/littlexia4-creator/nativelink-gcc:latest
```

Only `linux/amd64` is published — the upstream binary is `x86_64-unknown-linux-musl`.


## nativelink-osxcross-ubuntu

Same as nativelink-python but on a `ghcr.io/littlexia4-creator/osxcross-ubuntu` base, providing the macOS cross-compilation toolchain alongside the nativelink server. Useful for remote-execution workers that need to cross-compile for macOS.

### Image

```
ghcr.io/littlexia4-creator/nativelink-osxcross-ubuntu:latest
```

Only `linux/amd64` is published — the upstream binary is `x86_64-unknown-linux-musl`.

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/littlexia4-creator/DOCKERFILES/refs/heads/main/nativelink/nativelink-osxcross-ubuntu/install.sh | bash
```

## asio

Alpine-based image with [Asio](https://think-async.com/Asio/) (header-only C++ async I/O library), `g++`, and `make`. Use as a build environment for Asio-based networking applications.

### Image

```
ghcr.io/littlexia4-creator/asio:latest
```

Only `linux/amd64` is published.

### Test

```bash
bash asio/test/test.sh
```

## osxcross-ubuntu

Packages the [osxcross](https://github.com/tpoechtrager/osxcross) macOS cross-compilation toolchain on an Ubuntu base. The toolchain is copied from the [crazymax/osxcross](https://github.com/crazy-max/docker-osxcross/blob/main/Dockerfile) image and made available at `/osxcross`.

### Image

```
ghcr.io/littlexia4-creator/osxcross-ubuntu:latest
```

Only `linux/amd64` is published — osxcross is an x86 cross-compilation toolchain.

---

## Reference: image pipelines

| Image | Source path | Platforms | Trigger paths |
|-------|-------------|-----------|---------------|
| `ghcr.io/littlexia4-creator/proxy-server` | `proxy-server/src` | `linux/amd64,linux/arm64` | `proxy-server/src/**` |
| `ghcr.io/littlexia4-creator/nativelink-python` | `nativelink/nativelink-python/src` | `linux/amd64` | `nativelink/nativelink-python/src/**` |
| `ghcr.io/littlexia4-creator/nativelink-gcc` | `nativelink/nativelink-gcc/src` | `linux/amd64` | `nativelink/nativelink-gcc/src/**` |
| `ghcr.io/littlexia4-creator/osxcross-ubuntu` | `osxcross-ubuntu/src` | `linux/amd64` | `osxcross-ubuntu/src/**` |
| `ghcr.io/littlexia4-creator/nativelink-osxcross-ubuntu` | `nativelink/nativelink-osxcross-ubuntu/src` | `linux/amd64` | `nativelink/nativelink-osxcross-ubuntu/src/**` |
| `ghcr.io/littlexia4-creator/asio` | `asio/src` | `linux/amd64` | `asio/src/**` |
