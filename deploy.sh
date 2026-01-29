#!/bin/bash
# AlamiaConnect Multi-Tenant Deployment Script
# Usage: ./deploy.sh <client_name> <port> <branch>

set -e # Exit on error

# --- Sanitize Inputs (Remove potential \r or trailing spaces) ---
CLIENT_NAME=$(echo "$1" | tr -d '\r' | xargs)
PORT=$(echo "$2" | tr -d '\r' | xargs)
BRANCH=$(echo "$3" | tr -d '\r' | xargs)
BRANCH=${BRANCH:-main}

# --- Configuration ---
# NOTE: If you are using Docker installed via Snap, it may have trouble accessing /opt/.
# If this script fails with a "void" error, consider changing BASE_DEPLOY_PATH to /home/alamiaconnect/
BASE_DEPLOY_PATH="/opt/alamiaconnect"

# Get the directory where the script is located
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(echo "$SRC_DIR" | tr -d '\r' | xargs)

if [ -z "$CLIENT_NAME" ] || [ -z "$PORT" ]; then
    echo "❌ Usage: ./deploy.sh <client_name> <port> [branch]"
    echo "   Example: ./deploy.sh ktd 9001 ktd-main"
    exit 1
fi

TARGET_DIR="$BASE_DEPLOY_PATH/$CLIENT_NAME"

echo "🚀 Deploying AlamiaConnect for client: $CLIENT_NAME"
echo "📂 Source: $SRC_DIR"
echo "🎯 Target: $TARGET_DIR"
echo "🌐 Port: $PORT"
echo "🌿 Branch: $BRANCH"

# 1. Create target directory
mkdir -p "$TARGET_DIR"

# 2. Copy necessary files
echo "📦 Copying Docker infrastructure..."
cp "$SRC_DIR/Dockerfile" "$TARGET_DIR/"
cp "$SRC_DIR/docker-compose.yml" "$TARGET_DIR/"
cp "$SRC_DIR/entrypoint.sh" "$TARGET_DIR/"

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

# Determine Compose Command
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Detect if we are in a Snap environment
IS_SNAP=false
if [[ "$COMPOSE_CMD" == *"snap"* ]] || command -v snap >/dev/null && snap list docker >/dev/null 2>&1; then
    IS_SNAP=true
    echo "⚠️ Snap-based Docker detected."
fi

# THE FIX: Use absolute paths and the --project-directory flag
# This helps Snap-confined Docker processes resolve the path correctly.
# We run it from the target directory to ensure .env is picked up.
cd "$TARGET_DIR"

echo "📡 Executing: $COMPOSE_CMD -f $TARGET_DIR/docker-compose.yml up -d"

# We use -f with absolute path AND --project-directory for maximum compatibility
$COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" --project-directory "$TARGET_DIR" down || true
$COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" --project-directory "$TARGET_DIR" up -d --build

echo "✅ Deployment for $CLIENT_NAME initiated!"
echo "📡 Access via: http://your-vps-ip:$PORT"
echo "📝 Log Trace: $COMPOSE_CMD logs -f app"
