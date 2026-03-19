FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
     ca-certificates curl openssl python3 qrencode supervisor systemd-sysv \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor

COPY proxy-install.sh /usr/local/bin/proxy-install.sh
COPY proxy-verify.sh /usr/local/bin/proxy-verify.sh
COPY sing-box.conf /etc/supervisor/conf.d/sing-box.conf
COPY sub-server.conf /etc/supervisor/conf.d/sub-server.conf

RUN chmod +x /usr/local/bin/proxy-*.sh && /usr/local/bin/proxy-install.sh

EXPOSE 8443/udp                                                                                                    
EXPOSE 2083/tcp                                                 
EXPOSE 2096/tcp  

ENTRYPOINT ["/usr/bin/supervisord", "-n"]
