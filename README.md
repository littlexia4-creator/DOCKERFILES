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

## linux-bochs

Ubuntu 24.04 base runtime for running existing Linux 0.11 disk images with Ubuntu's Bochs packages. Includes the terminal launcher from `Linux0.11-Learning/docker`, which uses the host terminal's dimensions (defaulting to 80 columns and 25 rows without a TTY).

### Image

```
ghcr.io/littlexia4-creator/linux-bochs:latest
```

## linux-bochs-patch

Based on `linux-bochs`. Compiles Bochs from Ubuntu 24.04's source package with the terminal hardware-scrolling fix from `Linux0.11-Learning/docker/Dockerfile.bochs-patch` and installs the patched binary at `/usr/local/bin/bochs`.

Both images include:

- `/usr/local/bin/run-bochs`: the terminal launcher.
- `/usr/local/share/linux-bochs/bochsrc.bxrc`: the Bochs machine configuration.
- `/usr/local/share/linux-bochs/start.rc`: the debugger startup file.

The patched image inherits the entrypoint path, default arguments, and `/work` directory from the base runtime. It installs `linux-bochs-patch/src/bochs-terminal.sh` at `/usr/local/bin/run-bochs` to forward terminal input/output and close the container when Bochs exits. No host launcher bind mount is required.

### Image

```
ghcr.io/littlexia4-creator/linux-bochs-patch:latest
```

The shared workflow publishes both `linux/amd64` images with `latest` and commit SHA tags after changes reach `main`, or when manually triggered. It builds `linux-bochs` first, then builds `linux-bochs-patch` from that base image's exact digest.

### Build and run locally

Build the base runtime, then the patched runtime, from this repository:

```bash
docker build -t linux-bochs:local linux-bochs/src
docker build --build-arg BOCHS_IMAGE=linux-bochs:local \
    -t linux-bochs-patch:local linux-bochs-patch/src
```

`BOCHS_IMAGE` selects the base runtime. It defaults to `ghcr.io/littlexia4-creator/linux-bochs:latest` when building the patched image independently.

Run with an absolute path to the guest directory, using a POSIX shell:

```bash
docker run --rm -it --network=none \
    --mount "type=bind,source=/absolute/path/to/Linux0.11-Learning,target=/work" \
    linux-bochs-patch:local
```

Once published, use `ghcr.io/littlexia4-creator/linux-bochs-patch:latest` in place of `linux-bochs-patch:local`. Use `linux-bochs:local` to run Ubuntu's packaged emulator.

The guest directory must contain `Boot.img`, `rootimage-0.11.img`, and `hdc-0.11.img`. The image includes a Linux-compatible Bochs configuration and debugger startup file; no host Bochs installation is needed. It boots existing images and does not build the kernel.

The guest directory is mounted at `/work`, so disk changes and Bochs logs persist there. With a guest kernel that supports Bochs power-off, exiting the main console shell closes the emulator and container. Otherwise, run `sync` in the guest before pressing **Ctrl+]** to close the emulator.

On Git Bash, use a Windows source path such as `E:/Coding/.../Linux0.11-Learning` and prefix `docker run` with `MSYS_NO_PATHCONV=1` to preserve the container's `/work` path.

To customize Bochs, pass its arguments after the image name. These replace the image's default arguments, for example:

```bash
docker run --rm -it --network=none \
    --mount "type=bind,source=/absolute/path/to/Linux0.11-Learning,target=/work" \
    linux-bochs-patch:local \
    -q -f /usr/local/share/linux-bochs/bochsrc.bxrc \
    -rc /usr/local/share/linux-bochs/start.rc 'megs: 16'
```

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
| `ghcr.io/littlexia4-creator/linux-bochs` | `linux-bochs/src` | `linux/amd64` | `linux-bochs-patch/src/**`, `linux-bochs/src/**` |
| `ghcr.io/littlexia4-creator/linux-bochs-patch` | `linux-bochs-patch/src` | `linux/amd64` | `linux-bochs-patch/src/**`, `linux-bochs/src/**` |
