# AlamiaConnect Multi-Tenant Deployment Guide (The Gold Standard)

This document outlines the standardized architecture for deploying multiple isolated client and environment instances on a single VPS, incorporating both the Laravel Backend and Next.js Frontend.

## 1. Directory Structure

Deployments must follow a hierarchical structure to maintain a clean VPS home directory and allow for logical grouping.

**Root Path**: `/home/alamiaconnect/clients`

**Structure**:
```text
/home/alamiaconnect/
├── AlamiaConnect-Docker/      # Infrastructure & Deployment Scripts
├── AlamiaConnect-Backend/     # Master Backend Source (Auto-pulled)
├── AlamiaConnect-Frontnd/     # Master Frontend Source (Auto-pulled)
└── clients/
    └── <client_name>/
        └── <environment>/     # e.g., prod, demo, test
            ├── .env           # Stack configuration
            ├── docker-compose.yml
            ├── workspace/     # Backend code/volume
            └── .configs/      # Persistent DB & Configs
```

## 2. Port Management Standardization

To prevent port conflicts while keeping client services logically grouped, we use the following Offset Rules:

| Service | Port Mapping | Example (Base: 9300) |
| :--- | :--- | :--- |
| **Backend API** | `BASE_PORT` | `9300` |
| **phpMyAdmin** | `BASE_PORT + 10` | `9310` |
| **Frontend (Next.js)**| `BASE_PORT + 20` | `9320` |

> [!IMPORTANT]
> Always ensure `BASE_PORT` values are at least 100 digits apart for different clients (e.g., Client A starts at 9000, Client B at 9100).

## 3. Data Safety & Initialization

Our infrastructure includes a **Safety Switch** to prevent data loss during container restarts or infrastructure updates.

*   **Fresh Install**: If `storage/installed` does not exist, the `alamia:install-auto` command runs (Migrate Fresh + Seed).
*   **Update/Restart**: If the app is already installed, the container runs standard `migrate --force` to apply schema changes while preserving all client data.

## 4. Deployment Command

The `deploy.sh` script handles repository syncing for both Backend and Frontend, generates the environment configuration, and starts the stack.

```bash
# Usage:
./deploy.sh <client>/<env> <base_port> <backend_branch> <domain_name>

# Example (KTD Production):
./deploy.sh ktd/prod 9300 ktd-production ktd-crm.alamiaconnect.com
```

## 5. Network & CORS Logic

The deployment script automatically handles Cross-Origin Resource Sharing (CORS) and Sanctum authentication between the two subdomains:

1.  **Backend Host**: `ktd-crm.alamiaconnect.com`
2.  **Frontend Host**: `ktd.alamiaconnect.com` (Derived by replacing `-crm` with nothing)
3.  **CORS Allowed Origins**: Automatically set to allow the frontend subdomain to communicate with the backend.
4.  **Sanctum Stateful Domains**: Configured to trust the frontend for cookie-based authentication.
5.  **Session Domain**: Set to the parent domain (e.g., `.alamiaconnect.com`) to allow cookie sharing across subdomains.

## 6. Summary of Best Practices

1.  **Unified Stack**: Every client/env is a complete stack with Backend, Frontend, DB, and Redis.
2.  **Auto-Sync**: The script pulls the latest code from both repos before starting the build.
3.  **Standalone Builds**: The Frontend uses Next.js `standalone` mode in `Dockerfile.prod` for maximum VPS performance.
4.  **Security**: Each deployment gets a unique auto-generated `DB_PASSWORD`.
