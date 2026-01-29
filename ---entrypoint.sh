#!/bin/bash
set -e

# Configuration
WORKSPACE_DIR="/var/www/html"
REPO_URL=${BACKEND_REPO_URL}
REPO_BRANCH=${BACKEND_REPO_BRANCH:-main}

echo "Starting AlamiaConnect entrypoint logic..."

# 1. Ensure workspace is initialized
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    echo "Cloning backend repository from $REPO_URL ($REPO_BRANCH)..."
    git clone -b "$REPO_BRANCH" "$REPO_URL" "$WORKSPACE_DIR"
else
    echo "Updating backend repository..."
    git -C "$WORKSPACE_DIR" pull origin "$REPO_BRANCH"
fi

# 2. Permissions
echo "Setting permissions..."
chown -R $USER:www-data "$WORKSPACE_DIR"
chmod -R 775 "$WORKSPACE_DIR/storage" "$WORKSPACE_DIR/bootstrap/cache"

# 3. Environment Config
echo "Configuring environment..."
if [ -f "$WORKSPACE_DIR/../.configs/.env" ]; then
    cp "$WORKSPACE_DIR/../.configs/.env" "$WORKSPACE_DIR/.env"
elif [ ! -f "$WORKSPACE_DIR/.env" ]; then
    cp "$WORKSPACE_DIR/.env.example" "$WORKSPACE_DIR/.env"
fi

# 4. PHP Dependencies
echo "Installing PHP dependencies..."
composer install --no-interaction --optimize-autoloader

# 5. NPM Build Phase
echo "Starting NPM build phase..."
npm install

# Build root if vite exists
if [ -f "vite.config.js" ]; then
    echo "Building root assets..."
    npm run build
fi

# Build packages with vite.config.js
echo "Searching for package Vite configs..."
find packages -name "vite.config.js" | while read config_path; do
    package_dir=$(dirname "$config_path")
    echo "Building assets for package: $package_dir"
    cd "$WORKSPACE_DIR/$package_dir"
    npm install
    npm run build
    cd "$WORKSPACE_DIR"
done

# 6. Specialized Docker Installer
echo "Running AlamiaConnect Docker installer..."
php artisan alamia:install-docker --force

# 7. Final Clean up
php artisan optimize:clear

echo "AlamiaConnect is ready! Starting Apache..."
exec "$@"
