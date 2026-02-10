#!/bin/bash
# AlamiaConnect Multi-Tenant Deployment Script
# Usage: ./deploy.sh <client_name> <port> <branch> <domain_name>

set -e # Exit on error

# --- Sanitize Inputs ---
CLIENT_NAME=$(echo "$1" | tr -d '\r' | xargs | tr '[:upper:]' '[:lower:]')
PORT=$(echo "$2" | tr -d '\r' | xargs)
BRANCH=$(echo "$3" | tr -d '\r' | xargs)
DOMAIN_NAME=$(echo "$4" | tr -d '\r' | xargs)
PMA_PORT_OVERRIDE=$(echo "$5" | tr -d '\r' | xargs)

BRANCH=${BRANCH:-main}

if [ -z "$CLIENT_NAME" ] || [ -z "$PORT" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Usage: ./deploy.sh <client_name> <port> <branch> <domain_name> [pma_port]"
    echo "   Example: ./deploy.sh ktd/demo 9000 main crmdemo.alamiaconnect.com"
    echo "   (This creates clients/ktd/demo and sets App Port to 9000)"
    exit 1
fi

# --- Configuration ---
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(echo "$SRC_DIR" | tr -d '\r' | xargs)
BASE_PATH="$(dirname "$SRC_DIR")"

# Centralize all deployments into a 'clients' folder in the parent directory
DEPLOY_ROOT="$BASE_PATH/clients"
TARGET_DIR="$DEPLOY_ROOT/$CLIENT_NAME"

echo "🚀 Deploying AlamiaConnect for client: $CLIENT_NAME"
echo "📂 Source: $SRC_DIR"
echo "📂 Deploy Root: $DEPLOY_ROOT"
echo "🎯 Target: $TARGET_DIR"
echo "🌐 Port: $PORT"
echo "🌿 Branch: $BRANCH"
echo "🔗 Domain: $DOMAIN_NAME"

# 1. Create target directory
mkdir -p "$TARGET_DIR"

# 2. Check for existing password to prevent drift
DB_PASSWORD=""
if [ -f "$TARGET_DIR/.env" ]; then
    echo "🔍 Existing .env found, preserving password..."
    DB_PASSWORD=$(grep "^DB_PASSWORD=" "$TARGET_DIR/.env" | cut -d'=' -f2)
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "🔑 Generating new secure database password..."
    DB_PASSWORD=$(openssl rand -hex 12)
fi

# 3. Copy necessary files (Selective Copy)
echo "📦 Copying Docker infrastructure..."
cp "$SRC_DIR/Dockerfile" "$TARGET_DIR/"
cp "$SRC_DIR/docker-compose.yml" "$TARGET_DIR/"
cp "$SRC_DIR/entrypoint.sh" "$TARGET_DIR/"

if [ -d "$SRC_DIR/.configs" ]; then
    echo "⚙️ Syncing configuration files..."
    mkdir -p "$TARGET_DIR/.configs"
    # Only copy files, do NOT overwrite existing data volumes if they exist in the target
    find "$SRC_DIR/.configs" -maxdepth 1 -type f -exec cp {} "$TARGET_DIR/.configs/" \;
fi

mkdir -p "$TARGET_DIR/workspace"

# 4. Generate/Update .env file for Docker Compose
echo "⚙️ Updating stack .env file..."
# Docker project names cannot contain slashes, so we sanitize it
SAFE_PROJECT_SUFFIX=$(echo "$CLIENT_NAME" | tr '/' '-')
cat <<EOF > "$TARGET_DIR/.env"
PROJECT_NAME=alamia-$SAFE_PROJECT_SUFFIX
APP_PORT=$PORT
PMA_PORT=${PMA_PORT_OVERRIDE:-$((PORT + 10))}
FRONTEND_PORT=$((PORT + 20))
DB_PASSWORD=$DB_PASSWORD
BACKEND_REPO_URL=https://github.com/AlamiaSoft/AlamiaConnect-Backend
BACKEND_REPO_BRANCH=$BRANCH
IMAGE_NAME=ghcr.io/alamiasoft/alamia-connect-docker:main
APP_ENV=production
APP_DEBUG=false
APP_URL=https://$DOMAIN_NAME
SANCTUM_STATEFUL_DOMAINS=$(echo "$DOMAIN_NAME" | sed 's/ktd-crm/ktd/'),$DOMAIN_NAME
SESSION_DOMAIN=.$(echo "$DOMAIN_NAME" | cut -d'.' -f2-)
CORS_ALLOWED_ORIGINS=https://$(echo "$DOMAIN_NAME" | sed 's/ktd-crm/ktd/'),https://$DOMAIN_NAME
EOF

# 5. Ensure Frontend Repository is up to date
FRONTEND_DIR="$BASE_PATH/AlamiaConnect-Frontnd"
if [ ! -d "$FRONTEND_DIR" ]; then
    echo "📂 Cloning Frontend repository..."
    git clone https://github.com/AlamiaSoft/AlamiaConnect-Frontnd "$FRONTEND_DIR"
else
    echo "📂 Updating Frontend repository..."
    git -C "$FRONTEND_DIR" pull origin main
fi

# 6. Deploy
echo "🚢 Starting Docker containers..."
cd "$TARGET_DIR"

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# We use -v if you explicitly want to reset data, but here we prioritize uptime.
$COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" --project-directory "$TARGET_DIR" down || true
$COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" --project-directory "$TARGET_DIR" up -d --build

echo "✅ Deployment for $CLIENT_NAME initiated!"
echo "📡 Access via: https://$DOMAIN_NAME"
echo "🔑 Database Password: $DB_PASSWORD"
