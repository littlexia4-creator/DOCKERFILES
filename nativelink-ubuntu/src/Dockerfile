FROM ghcr.io/tracemachina/nativelink:rvpya7w878sm86gd028fgcz6j0prdj2y AS source

# FROM ubuntu:24.04 AS final 
# RUN export DEBIAN_FRONTEND="noninteractive" && apt-get update && apt-get install -y python3  

FROM python:3-slim AS final

# source dir: /nix/store/.../bin/nativelink
# dest dir: /bin/nativelink
COPY --from=source /nix/store/d9nsczcvwki502smc8vxmyks5hrvimkn-nativelink-x86_64-unknown-linux-musl-1.0.0-rc3/bin/nativelink /bin/nativelink

RUN chmod +x /bin/nativelink

ENTRYPOINT ["/bin/nativelink"]
