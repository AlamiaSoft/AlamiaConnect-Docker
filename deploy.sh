#!/bin/bash
# AlamiaConnect Multi-Tenant Deployment Script
# Usage: ./deploy.sh <client_name> <port> <branch>

set -e # Exit on error

# --- Sanitize Inputs (Aggressive \r stripping) ---
# This fixes issues when scripts are edited on Windows
CLIENT_NAME=$(echo "$1" | sed 's/\r//g')
PORT=$(echo "$2" | sed 's/\r//g')
BRANCH=$(echo "$3" | sed 's/\r//g')
BRANCH=${BRANCH:-main}

# --- Configuration ---
BASE_DEPLOY_PATH="/opt/alamiaconnect"
# Get the directory where the script is located
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(echo "$SRC_DIR" | sed 's/\r//g')

if [ -z "$CLIENT_NAME" ] || [ -z "$PORT" ]; then
    echo "❌ Usage: ./deploy.sh <client_name> <port> [branch]"
    echo "   Example: ./deploy.sh ktd 9001 ktd-main"
    exit 1
fi

TARGET_DIR="$BASE_DEPLOY_PATH/$CLIENT_NAME"

echo "🚀 Deploying AlamiaConnect for client: $CLIENT_NAME"
echo "📂 Source Directory: $SRC_DIR"
echo "🎯 Target Directory: $TARGET_DIR"
echo "🌐 Port: $PORT"
echo "🌿 Branch: $BRANCH"

# 1. Create target directory
mkdir -p "$TARGET_DIR"

# 2. Copy necessary files
echo "📦 Copying Docker infrastructure..."
cp "$SRC_DIR/Dockerfile" "$TARGET_DIR/"
cp "$SRC_DIR/docker-compose.yml" "$TARGET_DIR/"
cp "$SRC_DIR/entrypoint.sh" "$TARGET_DIR/"

# Copy .configs directory if it exists
if [ -d "$SRC_DIR/.configs" ]; then
    cp -r "$SRC_DIR/.configs" "$TARGET_DIR/"
fi

mkdir -p "$TARGET_DIR/workspace"

# 3. Generate .env file
echo "⚙️ Generating .env file..."
cat <<EOF > "$TARGET_DIR/.env"
PROJECT_NAME=alamia-$CLIENT_NAME
APP_PORT=$PORT
PMA_PORT=$((PORT - 921))
DB_PASSWORD=$(openssl rand -hex 12)
BACKEND_REPO_URL=https://github.com/AlamiaSoft/AlamiaConnect-Backend
BACKEND_REPO_BRANCH=$BRANCH
IMAGE_NAME=ghcr.io/alamiasoft/alamia-connect-docker:main
APP_ENV=production
EOF

# 4. Deploy
echo "🚢 Starting Docker containers..."
cd "$TARGET_DIR"

# Use 'docker compose' (v2) if available, otherwise 'docker-compose' (v1)
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "📡 Using command: $COMPOSE_CMD"

# IMPORTANT: Use relative paths for the -f flag to avoid variable-based path corruption
# Also explicitly use -f to be certain
$COMPOSE_CMD -f docker-compose.yml down || true
$COMPOSE_CMD -f docker-compose.yml up -d --build

echo "✅ Deployment for $CLIENT_NAME initiated!"
echo "📡 Access via: http://your-vps-ip:$PORT"
echo "📝 Log Trace: $COMPOSE_CMD logs -f app"
