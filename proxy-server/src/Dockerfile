FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
     ca-certificates curl openssl python3 qrencode supervisor systemd-sysv \
  && rm -rf /var/lib/apt/lists/*

# Install sing-box
RUN mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc \
  && chmod a+r /etc/apt/keyrings/sagernet.asc \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/sagernet.asc] https://deb.sagernet.org/ * *" | tee /etc/apt/sources.list.d/sagernet.list > /dev/null \
  && apt-get update -y && apt-get install -y sing-box \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor /etc/proxy

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY proxy-verify.sh /usr/local/bin/proxy-verify.sh
COPY sub-server.py /usr/local/bin/sub-server.py
COPY sing-box.conf /etc/supervisor/conf.d/sing-box.conf
COPY sub-server.conf /etc/supervisor/conf.d/sub-server.conf

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/proxy-verify.sh /usr/local/bin/sub-server.py

EXPOSE 8443/udp
EXPOSE 2083/tcp
EXPOSE 2096/tcp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
