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
# Fix for "dubious ownership" in newer Git versions
git config --global --add safe.directory "$WORKSPACE_DIR"

if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    echo "Cloning backend repository from $REPO_URL ($REPO_BRANCH)..."
    git clone -b "$REPO_BRANCH" "$REPO_URL" "$WORKSPACE_DIR"
else
    echo "Updating backend repository..."
    git -C "$WORKSPACE_DIR" pull origin "$REPO_BRANCH"
fi

# 3. Handle Environment Config
if [ ! -f "$WORKSPACE_DIR/.env" ]; then
    if [ -f "/var/www/html/.configs/.env" ]; then
        echo "Using environment config from .configs/.env"
        cp "/var/www/html/.configs/.env" "$WORKSPACE_DIR/.env"
    else
        echo "No .env found, copying from .env.example"
        cp "$WORKSPACE_DIR/.env.example" "$WORKSPACE_DIR/.env"
    fi
fi

# Inject dynamic DB credentials from environment variables (passed from docker-compose)
echo "Syncing environment variables with .env..."
[ ! -z "$DB_HOST" ] && sed -i "s/^DB_HOST=.*/DB_HOST=$DB_HOST/" "$WORKSPACE_DIR/.env"
[ ! -z "$DB_DATABASE" ] && sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" "$WORKSPACE_DIR/.env"
[ ! -z "$DB_PASSWORD" ] && sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" "$WORKSPACE_DIR/.env"

# 4. Link storage and set permissions before complex operations
cd "$WORKSPACE_DIR"
echo "Setting initial permissions..."
chown -R $APP_USER:www-data "$WORKSPACE_DIR"
chmod -R 775 storage bootstrap/cache

# 5. PHP Dependencies
echo "Installing/Updating PHP dependencies..."
composer install --no-interaction --optimize-autoloader

# 6. NPM Build Phase
# ... (same as before)

# 7. Wait for MySQL to be ready
echo "Checking database connectivity..."
MAX_TRIES=30
COUNT=0

# Use a PHP one-liner for a more robust connection check that doesn't rely on Laravel being fully ready
CHECK_CMD="php -r \"try { new PDO('mysql:host=$DB_HOST;dbname=$DB_DATABASE', 'root', '$DB_PASSWORD'); exit(0); } catch (Exception \$e) { exit(1); }\""

until eval $CHECK_CMD > /dev/null 2>&1 || [ $COUNT -eq $MAX_TRIES ]; do
    echo "Waiting for database connection at $DB_HOST ($((COUNT+1))/$MAX_TRIES)..."
    sleep 3
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $MAX_TRIES ]; then
    echo "❌ ERROR: Database connection could not be established."
    echo "Host: $DB_HOST, Database: $DB_DATABASE, User: root"
    echo "Please ensure the 'db' container is healthy and passwords match."
    exit 1
fi

# 8. AlamiaConnect Specialized Installer
echo "Running AlamiaConnect installer..."
php artisan alamia:install-auto --force

# 8. Final Clean up and Optimization
echo "Optimizing..."
php artisan storage:link || true
php artisan optimize:clear
php artisan vendor:publish --provider="Webkul\Core\Providers\CoreServiceProvider" --force || true

echo "AlamiaConnect is ready! Booting up Apache..."
exec "$@"
