#!/bin/bash
set -e

# Configuration
# These can be overridden via environment variables
WORKSPACE_DIR="/var/www/html/alamiaconnect"
REPO_URL=${BACKEND_REPO_URL}
REPO_BRANCH=${BACKEND_REPO_BRANCH:-main}
APP_USER=${USER_NAME:-alamia}

echo "Starting AlamiaConnect entrypoint logic..."

# 1. Ensure workspace directory exists and is owned by the user
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "Creating workspace directory: $WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"
fi

# 2. Initialize/Update repository
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    echo "Cloning backend repository from $REPO_URL ($REPO_BRANCH)..."
    git clone -b "$REPO_BRANCH" "$REPO_URL" "$WORKSPACE_DIR"
else
    echo "Updating backend repository..."
    git -C "$WORKSPACE_DIR" pull origin "$REPO_BRANCH"
fi

# 3. Handle Environment Config
# Check if external config exists, otherwise use example
if [ -f "/var/www/html/.configs/.env" ]; then
    echo "Using environment config from .configs/.env"
    cp "/var/www/html/.configs/.env" "$WORKSPACE_DIR/.env"
elif [ ! -f "$WORKSPACE_DIR/.env" ]; then
    echo "No .env found, copying from .env.example"
    cp "$WORKSPACE_DIR/.env.example" "$WORKSPACE_DIR/.env"
fi

# 4. Link storage and set permissions before complex operations
cd "$WORKSPACE_DIR"
echo "Setting initial permissions..."
chown -R $APP_USER:www-data "$WORKSPACE_DIR"
chmod -R 775 storage bootstrap/cache

# 5. PHP Dependencies
echo "Installing/Updating PHP dependencies..."
composer install --no-interaction --optimize-autoloader

# 6. NPM Build Phase
echo "Starting NPM build phase..."
if [ ! -d "node_modules" ] || [ "$APP_ENV" != "production" ]; then
    npm install --legacy-peer-deps
fi

# Build root if vite exists
if [ -f "vite.config.js" ]; then
    echo "Building root assets..."
    npm run build
fi

# Build packages with vite.config.js (Specialized for Alamia/Admin etc)
echo "Searching for package Vite configs..."
find packages -name "vite.config.js" | while read config_path; do
    package_dir=$(dirname "$config_path")
    echo "Found Vite config in: $package_dir"
    # Navigate to package dir, install and build
    (cd "$package_dir" && npm install --legacy-peer-deps && npm run build)
done

# 7. Wait for MySQL to be ready
# In Docker, the database service (db) might start a few seconds after the app
echo "Checking database connectivity..."
# We use a simple PHP loop to wait for the connection to be established
MAX_TRIES=30
COUNT=0
until php artisan db:monitor > /dev/null 2>&1 || [ $COUNT -eq $MAX_TRIES ]; do
    echo "Waiting for database connection ($((COUNT+1))/$MAX_TRIES)..."
    sleep 3
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $MAX_TRIES ]; then
    echo "ERROR: Database connection could not be established. Please check your DB_HOST and credentials."
    exit 1
fi

# 8. AlamiaConnect Specialized Installer
# This handles migrations, seeding, and core setup
echo "Running AlamiaConnect installer..."
php artisan alamia:install-auto --force

# 8. Final Clean up and Optimization
echo "Optimizing..."
php artisan storage:link || true
php artisan optimize:clear
php artisan vendor:publish --provider="Webkul\Core\Providers\CoreServiceProvider" --force || true

echo "AlamiaConnect is ready! Booting up Apache..."
exec "$@"
