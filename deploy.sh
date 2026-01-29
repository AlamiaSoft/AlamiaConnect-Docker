#!/bin/bash
# AlamiaConnect Multi-Tenant Deployment Script
# Usage: ./deploy.sh <client_name> <port> <branch> <domain_name>

set -e # Exit on error

# --- Sanitize Inputs ---
CLIENT_NAME=$(echo "$1" | tr -d '\r' | xargs | tr '[:upper:]' '[:lower:]')
PORT=$(echo "$2" | tr -d '\r' | xargs)
BRANCH=$(echo "$3" | tr -d '\r' | xargs)
DOMAIN_NAME=$(echo "$4" | tr -d '\r' | xargs)

BRANCH=${BRANCH:-main}

if [ -z "$CLIENT_NAME" ] || [ -z "$PORT" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Usage: ./deploy.sh <client_name> <port> <branch> <domain_name>"
    echo "   Example: ./deploy.sh demo 9000 develop/demo crmdemo.alamiaconnect.com"
    exit 1
fi

# --- Configuration ---
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(echo "$SRC_DIR" | tr -d '\r' | xargs)
BASE_DEPLOY_PATH="$(dirname "$SRC_DIR")"

TARGET_DIR="$BASE_DEPLOY_PATH/$CLIENT_NAME"

echo "🚀 Deploying AlamiaConnect for client: $CLIENT_NAME"
echo "📂 Source: $SRC_DIR"
echo "🎯 Target: $TARGET_DIR"
echo "🌐 Port: $PORT"
echo "🌿 Branch: $BRANCH"
echo "🔗 Domain: $DOMAIN_NAME"

# 1. Create target directory
mkdir -p "$TARGET_DIR"

# 2. Copy necessary files (Selective Copy)
echo "📦 Copying Docker infrastructure..."
cp "$SRC_DIR/Dockerfile" "$TARGET_DIR/"
cp "$SRC_DIR/docker-compose.yml" "$TARGET_DIR/"
cp "$SRC_DIR/entrypoint.sh" "$TARGET_DIR/"

if [ -d "$SRC_DIR/.configs" ]; then
    echo "⚙️ Syncing configuration files..."
    mkdir -p "$TARGET_DIR/.configs"
    find "$SRC_DIR/.configs" -maxdepth 1 -type f -exec cp {} "$TARGET_DIR/.configs/" \;
fi

mkdir -p "$TARGET_DIR/workspace"

# 3. Generate .env file for Docker Compose
echo "⚙️ Generating stack .env file..."
RANDOM_PASS=$(openssl rand -hex 12)
cat <<EOF > "$TARGET_DIR/.env"
PROJECT_NAME=alamia-$CLIENT_NAME
APP_PORT=$PORT
PMA_PORT=$((PORT - 921))
DB_PASSWORD=$RANDOM_PASS
BACKEND_REPO_URL=https://github.com/AlamiaSoft/AlamiaConnect-Backend
BACKEND_REPO_BRANCH=$BRANCH
IMAGE_NAME=ghcr.io/alamiasoft/alamia-connect-docker:main
APP_ENV=production
APP_DEBUG=false
APP_URL=https://$DOMAIN_NAME
EOF

# 4. Deploy
echo "🚢 Starting Docker containers..."
cd "$TARGET_DIR"

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

$COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" --project-directory "$TARGET_DIR" down || true
$COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" --project-directory "$TARGET_DIR" up -d --build

echo "✅ Deployment for $CLIENT_NAME initiated!"
echo "📡 Access via: https://$DOMAIN_NAME"
echo "🔑 Database Password (random): $RANDOM_PASS"
