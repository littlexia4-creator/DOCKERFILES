FROM ubuntu:24.04

RUN apt-get -o Acquire::Retries=0 -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20 update \
 && DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=0 -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20 install -y --no-install-recommends bochs bochs-term bochsbios vgabios \
 && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 run-bochs.sh /usr/local/bin/run-bochs
COPY bochsrc.bxrc start.rc /usr/local/share/linux-bochs/

ENV TERM=xterm
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/run-bochs"]
CMD ["-q", "-f", "/usr/local/share/linux-bochs/bochsrc.bxrc", "-rc", "/usr/local/share/linux-bochs/start.rc"]
