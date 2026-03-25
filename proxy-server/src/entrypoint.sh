#!/bin/bash
#
# Entrypoint script for proxy-server container
# Generates configs with dynamic SERVER_IP at runtime

set -e

# ============== Config ==============
COUNTRY_CODE="${COUNTRY_CODE:-}"
NODE_NAME="${NODE_NAME:-}"
SERVER_IP="${SERVER_IP:-}"
HY2_PORT=8443
VLESS_PORT=2083
SUB_PORT=2096
REALITY_SNI="www.microsoft.com"
CREDENTIALS_FILE="/etc/proxy/credentials"
# ====================================

info() { echo "[INFO] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

# Load or generate credentials
load_or_generate_credentials() {
    if [ -f "$CREDENTIALS_FILE" ]; then
        info "Loading existing credentials..."
        source "$CREDENTIALS_FILE"
    else
        info "Generating new credentials..."
        mkdir -p /etc/proxy

        REALITY_KEYS=$(sing-box generate reality-keypair)
        REALITY_PRIVATE_KEY=$(echo "$REALITY_KEYS" | grep PrivateKey | awk '{print $2}')
        REALITY_PUBLIC_KEY=$(echo "$REALITY_KEYS" | grep PublicKey | awk '{print $2}')
        VLESS_UUID=$(sing-box generate uuid)
        HY2_PASSWORD=$(openssl rand -base64 16)
        SHORT_ID=$(openssl rand -hex 8)
        SUB_TOKEN=$(openssl rand -hex 16)

        cat > "$CREDENTIALS_FILE" << EOF
REALITY_PRIVATE_KEY="$REALITY_PRIVATE_KEY"
REALITY_PUBLIC_KEY="$REALITY_PUBLIC_KEY"
VLESS_UUID="$VLESS_UUID"
HY2_PASSWORD="$HY2_PASSWORD"
SHORT_ID="$SHORT_ID"
SUB_TOKEN="$SUB_TOKEN"
EOF
        chmod 600 "$CREDENTIALS_FILE"
        info "Credentials saved to $CREDENTIALS_FILE"
    fi
}

# Detect server IP
detect_server_ip() {
    if [ -z "$SERVER_IP" ]; then
        info "Detecting server IP..."
        SERVER_IP=$(curl -s4 --connect-timeout 5 ifconfig.me 2>/dev/null || \
                    curl -s4 --connect-timeout 5 ip.sb 2>/dev/null || \
                    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
        [ -z "$SERVER_IP" ] && error "Unable to detect server IP. Set SERVER_IP environment variable."
    fi
    info "Server IP: $SERVER_IP"
    export SERVER_IP
}

# Detect country from public IP
# using ipinfo.io API
detect_country() {
# {
#   "ip": "38.76.220.13",
#   "city": "Hong Kong",
#   "region": "Hong Kong",
#   "country": "HK",
#   "loc": "22.2783,114.1747",
#   "org": "AS401701 cognetcloud INC",
#   "postal": "999077",
#   "timezone": "Asia/Hong_Kong",
#   "readme": "https://ipinfo.io/missingauth"
# }
    if [ -z "$COUNTRY_CODE" ]; then
        info "Detecting country from IP..."
        COUNTRY_CODE=$(curl -s4 --connect-timeout 5 ipinfo.io/country 2>/dev/null || echo "Unknown")
    fi
    info "Detected country: $COUNTRY_CODE"
    export COUNTRY_CODE
}

# Generate SSL certificate
generate_ssl_cert() {
    info "Generating SSL certificate..."
    mkdir -p /root/cert/ip
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -days 3650 -nodes -subj "/CN=$SERVER_IP" \
        -keyout /root/cert/ip/privkey.pem -out /root/cert/ip/fullchain.pem 2>/dev/null
}

# Generate sing-box config
generate_singbox_config() {
    info "Generating sing-box config..."

    if [ -n "$NODE_NAME" ]; then
        HY2_NAME="${COUNTRY_CODE} Hysteria2-${NODE_NAME}"
        VLESS_NAME="${COUNTRY_CODE} Reality-${NODE_NAME}"
    else
        HY2_NAME="${COUNTRY_CODE} Hysteria2-${SERVER_IP}"
        VLESS_NAME="${COUNTRY_CODE} Reality-${SERVER_IP}"
    fi

    mkdir -p /etc/sing-box
    cat > /etc/sing-box/config.json << EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": ${HY2_PORT},
      "users": [
        {
          "password": "${HY2_PASSWORD}"
        }
      ],
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/root/cert/ip/fullchain.pem",
        "key_path": "/root/cert/ip/privkey.pem"
      }
    },
    {
      "type": "vless",
      "tag": "vless-reality-in",
      "listen": "::",
      "listen_port": ${VLESS_PORT},
      "users": [
        {
          "uuid": "${VLESS_UUID}",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${REALITY_SNI}",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "${REALITY_SNI}",
            "server_port": 443
          },
          "private_key": "${REALITY_PRIVATE_KEY}",
          "short_id": ["${SHORT_ID}"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF
    sing-box check -c /etc/sing-box/config.json || error "sing-box config check failed"
}

# Generate subscription configs
generate_subscription_configs() {
    info "Generating subscription configs..."
    mkdir -p /var/www

    # Clash subscription
    cat > /var/www/clash-sub.yaml << EOF
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
unified-delay: true
find-process-mode: strict
global-client-fingerprint: chrome

proxies:
  - name: "${HY2_NAME}"
    type: hysteria2
    server: ${SERVER_IP}
    port: ${HY2_PORT}
    password: "${HY2_PASSWORD}"
    alpn:
      - h3
    skip-cert-verify: true

  - name: "${VLESS_NAME}"
    type: vless
    server: ${SERVER_IP}
    port: ${VLESS_PORT}
    uuid: ${VLESS_UUID}
    network: tcp
    udp: true
    tls: true
    flow: xtls-rprx-vision
    client-fingerprint: chrome
    servername: ${REALITY_SNI}
    reality-opts:
      public-key: ${REALITY_PUBLIC_KEY}
      short-id: "${SHORT_ID}"

proxy-groups:
  - name: "Proxy"
    type: select
    proxies:
      - "${HY2_NAME}"
      - "${VLESS_NAME}"
      - DIRECT

  - name: "Auto Select"
    type: url-test
    proxies:
      - "${HY2_NAME}"
      - "${VLESS_NAME}"
    url: "https://www.gstatic.com/generate_204"
    interval: 300
    tolerance: 100

rules:
  - GEOIP,CN,DIRECT
  - MATCH,Proxy
EOF

    # v2rayN subscription
    HY2_LINK="hysteria2://${HY2_PASSWORD}@${SERVER_IP}:${HY2_PORT}?insecure=1&sni=${SERVER_IP}#${HY2_NAME}"
    VLESS_LINK="vless://${VLESS_UUID}@${SERVER_IP}:${VLESS_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp#${VLESS_NAME}"
    V2RAYN_CONTENT=$(echo -e "${HY2_LINK}\n${VLESS_LINK}" | base64 -w 0)
    echo "$V2RAYN_CONTENT" > /var/www/v2rayn-sub.txt

    # Export for sub-server.py
    export SUB_TOKEN
    export SUB_PORT
}

# Save proxy info
save_proxy_info() {
    cat > /root/proxy-info.txt << EOF
============================================
       PROXY Deployment Info
============================================

Clash subscription URL (mihomo/Clash.Meta):
http://${SERVER_IP}:${SUB_PORT}/${SUB_TOKEN}/clash.yaml

v2rayN subscription URL:
http://${SERVER_IP}:${SUB_PORT}/${SUB_TOKEN}/v2rayn.txt

--- Hysteria2 node (primary) ---
Server:   ${SERVER_IP}
Port:     ${HY2_PORT}
Password: ${HY2_PASSWORD}

--- VLESS+Reality node (backup) ---
Server:     ${SERVER_IP}
Port:       ${VLESS_PORT}
UUID:       ${VLESS_UUID}
PublicKey:  ${REALITY_PUBLIC_KEY}
PrivateKey: ${REALITY_PRIVATE_KEY}
ShortID:    ${SHORT_ID}
SNI:        ${REALITY_SNI}

Client tips (Shadowrocket / Reality):
If VLESS+Reality times out, enable in client:
- TCP Fast Open
- Allow Insecure
EOF
}

# Main
main() {
    load_or_generate_credentials
    detect_server_ip
    detect_country
    generate_ssl_cert
    generate_singbox_config
    generate_subscription_configs
    save_proxy_info

    info "Starting supervisord..."
    exec /usr/bin/supervisord -n
}

main
