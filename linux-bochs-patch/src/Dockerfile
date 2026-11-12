ARG BOCHS_IMAGE=ghcr.io/littlexia4-creator/linux-bochs:latest
FROM ubuntu:24.04 AS bochs-build

# Build Bochs with the terminal renderer's hardware-scrolling fix.
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources \
 && apt-get -o Acquire::Retries=0 -o Acquire::http::Timeout=20 update \
 && DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=0 -o Acquire::http::Timeout=20 install -y --no-install-recommends build-essential dpkg-dev libncurses-dev libtool \
 && mkdir /build \
 && cd /build \
 && apt-get source bochs

RUN DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=0 -o Acquire::http::Timeout=20 install -y --no-install-recommends autoconf automake libltdl-dev

COPY bochs-term-scroll.patch /build/
RUN cd /build/bochs-*/ \
 && patch -p1 < /build/bochs-term-scroll.patch \
 && libtoolize --force --copy \
 && aclocal --force -I . -I libltdl/m4 \
 && autoconf \
 && ./configure --prefix=/usr/local --with-term --without-x11 \
      --enable-debugger --disable-debugger-gui --enable-disasm \
      --disable-plugins --enable-idle-hack --disable-docbook --disable-readline \
 && make -j4 bochs \
 && install -s bochs /bochs

FROM ${BOCHS_IMAGE}
COPY --from=bochs-build --chmod=755 /bochs /usr/local/bin/bochs
COPY --chmod=755 bochs-terminal.sh /usr/local/bin/run-bochs
