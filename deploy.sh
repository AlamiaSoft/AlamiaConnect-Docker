#!/bin/bash
# AlamiaConnect Multi-Tenant Deployment Script
# Usage: ./deploy.sh <client_name> <port> <branch>

# --- Configuration ---
BASE_DEPLOY_PATH="/opt/alamiaconnect"
SRC_DIR="$(pwd)" # Assuming you run this from the repo root

CLIENT_NAME=$1
PORT=$2
BRANCH=$3

if [ -z "$CLIENT_NAME" ] || [ -z "$PORT" ]; then
    echo "Usage: ./deploy.sh <client_name> <port> [branch]"
    echo "Example: ./deploy.sh ktd 9001 ktd-main"
    exit 1
fi

BRANCH=${BRANCH:-main}
TARGET_DIR="$BASE_DEPLOY_PATH/$CLIENT_NAME"

echo "🚀 Deploying AlamiaConnect for client: $CLIENT_NAME"
echo "📂 Target Directory: $TARGET_DIR"
echo "🌐 Port: $PORT"
echo "🌿 Branch: $BRANCH"

# 1. Create target directory
mkdir -p "$TARGET_DIR"

# 2. Copy necessary files
echo "📦 Copying Docker infrastructure..."
cp -r "$SRC_DIR/Dockerfile" "$TARGET_DIR/"
cp -r "$SRC_DIR/docker-compose.yml" "$TARGET_DIR/"
cp -r "$SRC_DIR/entrypoint.sh" "$TARGET_DIR/"
cp -r "$SRC_DIR/.configs" "$TARGET_DIR/"
mkdir -p "$TARGET_DIR/workspace"

# 3. Generate .env file
echo "⚙️ Generating .env file..."
cat <<EOF > "$TARGET_DIR/.env"
PROJECT_NAME=alamia-$CLIENT_NAME
APP_PORT=$PORT
PMA_PORT=$((PORT - 921)) # Generates a unique PMA port, e.g., 9001 -> 8080
DB_PASSWORD=$(openssl rand -hex 12)

# Backend Repository Configuration
BACKEND_REPO_URL=https://github.com/AlamiaSoft/AlamiaConnect-Backend
BACKEND_REPO_BRANCH=$BRANCH

# Docker Image
IMAGE_NAME=ghcr.io/alamiasoft/alamia-connect-docker:main

# Application Environment
APP_ENV=production
EOF

# 4. Deploy
echo "🚢 Starting Docker containers..."
cd "$TARGET_DIR"
docker-compose down
docker-compose up -d --build

echo "✅ Deployment for $CLIENT_NAME initiated!"
echo "📡 Access via: http://your-vps-ip:$PORT"
echo "📝 Log Trace: docker-compose logs -f app"
