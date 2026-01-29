#!/bin/bash
# AlamiaConnect Multi-Tenant Deployment Script
# Usage: ./deploy.sh <client_name> <port> <branch>

set -e # Exit on error

# --- Sanitize Inputs (Remove potential \r characters from Windows environments) ---
CLIENT_NAME=$(echo "$1" | tr -d '\r')
PORT=$(echo "$2" | tr -d '\r')
BRANCH=$(echo "$3" | tr -d '\r')
BRANCH=${BRANCH:-main}

# --- Configuration ---
BASE_DEPLOY_PATH="/opt/alamiaconnect"
# Get the directory where the script is located, ensuring absolute paths
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=$(echo "$SRC_DIR" | tr -d '\r')

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
REQUIRED_FILES=("Dockerfile" "docker-compose.yml" "entrypoint.sh")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SRC_DIR/$file" ]; then
        echo "❌ Error: $file not found in $SRC_DIR"
        exit 1
    fi
    cp "$SRC_DIR/$file" "$TARGET_DIR/"
done

# Copy .configs directory if it exists
if [ -d "$SRC_DIR/.configs" ]; then
    cp -r "$SRC_DIR/.configs" "$TARGET_DIR/"
else
    echo "⚠️ Warning: .configs directory not found in $SRC_DIR. Initialization might fail."
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

# Debug: List files to ensure we are in the right place
echo "🔍 Current Directory Contents:"
ls -la

# Use 'docker compose' (v2) if available, otherwise 'docker-compose' (v1)
DOCKER_COMPOSE_CMD="docker-compose"
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
fi

echo "📡 Using command: $DOCKER_COMPOSE_CMD"

# Explicitly use the file to avoid "not found" errors
$DOCKER_COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" down || true
$DOCKER_COMPOSE_CMD -f "$TARGET_DIR/docker-compose.yml" up -d --build

echo "✅ Deployment for $CLIENT_NAME initiated!"
echo "📡 Access via: http://your-vps-ip:$PORT"
echo "📝 Log Trace: $DOCKER_COMPOSE_CMD -f $TARGET_DIR/docker-compose.yml logs -f app"
