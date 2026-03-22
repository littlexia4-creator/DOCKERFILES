# DOCKERFILES

A collection of Dockerfiles for quick server deployment.

## proxy-server

Deploys **Hysteria2** (primary) + **VLESS+Reality** (backup) dual-protocol proxy with a Clash subscription service.

### Ports

| Port | Protocol | Service |
|------|----------|---------|
| 8443 | UDP | Hysteria2 |
| 2083 | TCP | VLESS+Reality |
| 2096 | TCP | Clash subscription |

### Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/littlexia4-creator/DOCKERFILES/refs/heads/main/proxy-server/quick-start.sh | bash
```

### Subscription

After deployment, run verify script to get subscription URLs:

```bash
docker exec proxy-server /usr/local/bin/proxy-verify.sh
```

| Client | Subscription URL |
|--------|------------------|
| mihomo / Clash.Meta | `http://<IP>:2096/<token>/clash.yaml` |
| v2rayN | `http://<IP>:2096/<token>/v2rayn.txt` |
