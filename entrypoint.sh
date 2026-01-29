#!/bin/bash
set -e

# --- Configuration ---
WORKSPACE_DIR="/var/www/html/alamiaconnect"
APP_USER=${USER_NAME:-alamia}
REPO_URL=${BACKEND_REPO_URL:-https://github.com/AlamiaSoft/AlamiaConnect-Backend}
REPO_BRANCH=${BACKEND_REPO_BRANCH:-main}

echo "Starting AlamiaConnect entrypoint logic..."

# 1. Standardize Ownership
# Ensure workspace exists
mkdir -p "$WORKSPACE_DIR"

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

# Inject dynamic DB credentials and APP settings from environment variables
echo "Syncing environment variables with .env..."
[ ! -z "$DB_HOST" ] && sed -i "s/^DB_HOST=.*/DB_HOST=$DB_HOST/" "$WORKSPACE_DIR/.env"
[ ! -z "$DB_DATABASE" ] && sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" "$WORKSPACE_DIR/.env"
[ ! -z "$DB_PASSWORD" ] && sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" "$WORKSPACE_DIR/.env"
[ ! -z "$APP_URL" ] && sed -i "s|^APP_URL=.*|APP_URL=$APP_URL|" "$WORKSPACE_DIR/.env"
[ ! -z "$APP_ENV" ] && sed -i "s/^APP_ENV=.*/APP_ENV=$APP_ENV/" "$WORKSPACE_DIR/.env"
[ ! -z "$APP_DEBUG" ] && sed -i "s/^APP_DEBUG=.*/APP_DEBUG=$APP_DEBUG/" "$WORKSPACE_DIR/.env"

# Logic for "Local Network" prompt fix:
# Often triggered by Echo server Defaults. Force to log if unset to prevent broadcast discovery triggers.
sed -i "s/^BROADCAST_DRIVER=.*/BROADCAST_DRIVER=log/" "$WORKSPACE_DIR/.env"

# 4. Link storage and set permissions
cd "$WORKSPACE_DIR"
echo "Refining permissions..."
chown -R $APP_USER:www-data "$WORKSPACE_DIR"
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

# 5. PHP Dependencies
echo "Ensuring PHP dependencies are optimized..."
composer install --no-interaction --optimize-autoloader

# 6. NPM Build Phase & Asset Refresh
echo "Starting NPM build phase..."
npm install --legacy-peer-deps

# Build root if vite exists
if [ -f "vite.config.js" ]; then
    echo "Building root assets..."
    npm run build
fi

# Build packages with vite.config.js (Specialized for Alamia/Admin etc)
find packages -name "vite.config.js" | while read config_path; do
    package_dir=$(dirname "$config_path")
    echo "Found Vite config in: $package_dir"
    (cd "$package_dir" && npm install --legacy-peer-deps && npm run build)
done

# 7. Robust Storage Link
echo "Repairing storage symlinks..."
rm -rf public/storage
php artisan storage:link

# 8. Wait for MySQL to be ready
echo "Checking database connectivity..."
MAX_TRIES=30
COUNT=0
CHECK_CMD="php -r \"try { new PDO('mysql:host=$DB_HOST;dbname=$DB_DATABASE', 'root', '$DB_PASSWORD'); exit(0); } catch (Exception \$e) { exit(1); }\""

until eval $CHECK_CMD > /dev/null 2>&1 || [ $COUNT -eq $MAX_TRIES ]; do
    echo "Waiting for database connection at $DB_HOST ($((COUNT+1))/$MAX_TRIES)..."
    sleep 3
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $MAX_TRIES ]; then
    echo "❌ ERROR: Database connection could not be established."
    exit 1
fi

# 9. AlamiaConnect Specialized Installer & Cache Clear
echo "Running AlamiaConnect specialized installer..."
php artisan alamia:install-auto --force

echo "Clearing application cache and optimizing branding..."
php artisan view:clear
php artisan cache:clear
php artisan route:clear
php artisan config:clear
php artisan optimize:clear

# 10. Final Ownership check
chown -R $APP_USER:www-data storage bootstrap/cache public/storage

echo "✅ Entrypoint logic completed!"

exec "$@"
