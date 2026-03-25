#!/bin/bash
#
# proxy status verification script
# Usage: bash proxy-verify.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ============== 1. Verify ==============
supervisorctl status sing-box | grep -q "RUNNING" && info "sing-box is running" || error "sing-box is not running"
supervisorctl status sub-server | grep -q "RUNNING" && info "Subscription service is running" || error "Subscription service is not running"

# ============== 2. Print /root/proxy-info.txt ==============
if [ -f /root/proxy-info.txt ]; then
  info "Proxy information:"
  cat /root/proxy-info.txt
else
  error "Proxy information file not found"
fi

# ============== 3. Show subscription QR code ==============
CLASH_URL=$(grep -oP 'http://\S+/clash\.yaml' /root/proxy-info.txt 2>/dev/null)
V2RAYN_URL=$(grep -oP 'http://\S+/v2rayn\.txt' /root/proxy-info.txt 2>/dev/null)

# Extract path and check via localhost (container can't reach its own public IP)
check_url() {
  local url="$1"
  local path=$(echo "$url" | sed 's|.*://[^/]*||')
  curl --head --silent --fail "http://127.0.0.1:2096${path}" > /dev/null 2>&1
}

if [ -n "$CLASH_URL" ]; then
  if check_url "$CLASH_URL"; then
      echo ""
      echo -e "${YELLOW}=== Scan QR code for Clash subscription ===${NC}"
      qrencode -t ANSIUTF8 "$CLASH_URL"
  else
    error "CLASH_URL is not reachable"
  fi
fi

if [ -n "$V2RAYN_URL" ]; then
  if check_url "$V2RAYN_URL"; then
    echo ""
    echo -e "${YELLOW}=== Scan QR code for v2rayN subscription ===${NC}"
    qrencode -t ANSIUTF8 "$V2RAYN_URL"
  else
    error "V2RAYN_URL is not reachable"
  fi
fi
