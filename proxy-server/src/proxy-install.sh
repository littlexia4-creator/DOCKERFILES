#!/bin/bash
#
# proxy quick-deployment script (install)
# Run on a fresh Ubuntu 22.04/24.04 VPS
# Deploy Hysteria2 (primary) + VLESS+Reality (backup) dual protocol
#
# Usage: bash proxy-install.sh [node_name] [server_ip]
# Example: bash proxy-install.sh "New York" 192.227.169.163
#          bash proxy-install.sh "Los Angeles"
#          bash proxy-install.sh. # Run directly on the server

set -e

# ============== Config (customizable) ==============
NODE_NAME="${1:-}"               # Node name (e.g., New York, Los Angeles, Tokyo)
HY2_PORT=8443                    # Hysteria2 port
VLESS_PORT=2083                  # VLESS Reality port
SUB_PORT=2096                    # Subscription service port
REALITY_SNI="www.microsoft.com"  # Reality disguise domain
# ================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check root
[ "$(id -u)" -ne 0 ] && error "Please run this script as root"

# Get server IP
SERVER_IP="${2:-$(curl -s4 ifconfig.me || curl -s4 ip.sb)}"
[ -z "$SERVER_IP" ] && error "Unable to get server IP. Specify manually: bash proxy-install.sh <name> <IP>"
info "Server IP: $SERVER_IP"

# Generate node display names
if [ -n "$NODE_NAME" ]; then
    HY2_NAME="Hysteria2-${NODE_NAME}"
    VLESS_NAME="Reality-${NODE_NAME}"
else
    HY2_NAME="Hysteria2-${SERVER_IP}"
    VLESS_NAME="Reality-${SERVER_IP}"
fi
info "Node names: $HY2_NAME / $VLESS_NAME"

# ============== 1. System update ==============
info "Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt update -y && apt upgrade -y
apt install -y curl socat openssl

# ============== 2. Install sing-box ==============
info "Installing sing-box..."
curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc
chmod a+r /etc/apt/keyrings/sagernet.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/sagernet.asc] https://deb.sagernet.org/ * *" | tee /etc/apt/sources.list.d/sagernet.list > /dev/null
apt update -y && apt install -y sing-box
info "sing-box $(sing-box version | head -1) installed"

# ============== 3. Generate SSL cert ==============
info "Generating self-signed SSL certificate..."
mkdir -p /root/cert/ip
# Let's Encrypt doesn't support bare IPs, so use a self-signed cert
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
    -days 3650 -nodes -subj "/CN=$SERVER_IP" \
    -keyout /root/cert/ip/privkey.pem -out /root/cert/ip/fullchain.pem
info "Self-signed SSL certificate generated"

# ============== 4. Generate keys and credentials ==============
info "Generating keys..."
REALITY_KEYS=$(sing-box generate reality-keypair)
REALITY_PRIVATE_KEY=$(echo "$REALITY_KEYS" | grep PrivateKey | awk '{print $2}')
REALITY_PUBLIC_KEY=$(echo "$REALITY_KEYS" | grep PublicKey | awk '{print $2}')
VLESS_UUID=$(sing-box generate uuid)
HY2_PASSWORD=$(openssl rand -base64 16)
SHORT_ID=$(openssl rand -hex 8)
SUB_TOKEN=$(openssl rand -hex 16)

# ============== 5. Write sing-box config ==============
info "Configuring sing-box..."
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

# ============== 6. Generate Clash subscription config ==============
info "Generating Clash subscription config..."
mkdir -p /var/www
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

# ============== 7. Create subscription service ==============
info "Creating subscription service..."
cat > /usr/local/bin/sub-server.py << PYEOF
import http.server

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/${SUB_TOKEN}/clash.yaml":
            self.send_response(200)
            self.send_header("Content-Type", "text/yaml; charset=utf-8")
            self.send_header("Content-Disposition", "attachment; filename=clash.yaml")
            self.end_headers()
            with open("/var/www/clash-sub.yaml", "rb") as f:
                self.wfile.write(f.read())
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, format, *args):
        pass

server = http.server.HTTPServer(("0.0.0.0", ${SUB_PORT}), Handler)
server.serve_forever()
PYEOF

cat > /etc/systemd/system/sub-server.service << SVCEOF
[Unit]
Description=Clash Subscription Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/sub-server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVCEOF


# ============== 8. Output results ==============
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}       PROXY install complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}=== Clash subscription URL (mihomo/Clash.Meta) ===${NC}"
echo -e "http://${SERVER_IP}:${SUB_PORT}/${SUB_TOKEN}/clash.yaml"
echo ""
echo -e "${YELLOW}=== Hysteria2 node (primary) ===${NC}"
echo "Server:   ${SERVER_IP}"
echo "Port:     ${HY2_PORT}"
echo "Password: ${HY2_PASSWORD}"
echo ""
echo -e "${YELLOW}=== VLESS+Reality node (backup) ===${NC}"
echo "Server:   ${SERVER_IP}"
echo "Port:     ${VLESS_PORT}"
echo "UUID:     ${VLESS_UUID}"
echo "PublicKey: ${REALITY_PUBLIC_KEY}"
echo "ShortID:  ${SHORT_ID}"
echo "SNI:      ${REALITY_SNI}"
echo ""
echo -e "${YELLOW}=== Config files ===${NC}"
echo "/etc/sing-box/config.json       # sing-box config"
echo "/var/www/clash-sub.yaml         # Clash subscription config"
echo ""

# Save info to file
cat > /root/proxy-info.txt << INFOEOF
============================================
       PROXY Deployment Info
============================================

Clash subscription URL:
http://${SERVER_IP}:${SUB_PORT}/${SUB_TOKEN}/clash.yaml

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
INFOEOF