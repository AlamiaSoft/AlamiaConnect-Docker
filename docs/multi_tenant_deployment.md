# AlamiaConnect Multi-Tenant Deployment Guide (The Gold Standard)

This document outlines the standardized architecture for deploying multiple isolated client and environment instances on a single VPS.

## 1. Directory Structure

Deployments must follow a hierarchical structure to maintain a clean VPS home directory and allow for logical grouping.

**Root Path**: `/home/alamiaconnect/clients`

**Structure**:
```text
/home/alamiaconnect/
└── clients/
    ├── <client_name>/
    │   ├── prod/          # Production Environment
    │   └── demo/          # Demo/Testing Environment
    └── nextjs-apps/       # (Coming Soon) Frontend instances
```

## 2. Port Management Standardization (+10 Rule)

To prevent port conflicts on the host while keeping client services logically grouped, we use the **+10 Offset Rule**.

| Service | Port Assignment |
| :--- | :--- |
| **App (Apache/PHP)** | `PRIMARY_PORT` (e.g., 9000, 9100, 9200) |
| **phpMyAdmin** | `PRIMARY_PORT + 10` (e.g., 9010, 9110, 9210) |

> [!IMPORTANT]
> Always ensure `PRIMARY_PORT` values are at least 100 digits apart for different clients to leave room for future services (e.g., App 1 starts at 9000, App 2 at 9100).

## 3. Deployment Command

Use the `deploy.sh` script to automate the creation of these instances.

```bash
# General Usage:
./deploy.sh <client>/<env> <port> <branch> <domain>

# Example (KTD Demo):
./deploy.sh ktd/demo 9100 ktd-main demo.kausartrade.com
```

## 4. Network Path & Routing (Cloudflare Tunnels)

For modern Docker deployments, we bypass the host Reverse Proxy (like CloudPanel) and connect the Cloudflare Tunnel directly to the Docker port.

**Correct Route**:
`Cloudflare Edge` -> `Cloudflare Tunnel (on VPS)` -> `http://localhost:<PRIMARY_PORT>`

**Why not CloudPanel Reverse Proxy?**
Bypassing CloudPanel eliminates potential SSL handshake failures (502 errors) and protocol mismatches, as the Tunnel handles encryption all the way to the host.

## 5. Summary of Best Practices

1. **Isolation**: Every client/env is a separate Docker stack with its own DB, Redis, and files.
2. **Sanitization**: The script replaces slashes with hyphens in Docker project names automatically.
3. **Persistance**: Database files are stored in `.configs/mysql-data` within the target client directory.
4. **Security**: Each deployment gets a unique auto-generated `DB_PASSWORD`.
