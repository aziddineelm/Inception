#!/bin/bash
# ==============================================================================
# WordPress + PHP-FPM Entrypoint Script
# ==============================================================================
# This script:
#   1. Waits for MariaDB to be ready (prevents race condition)
#   2. Downloads WordPress via WP-CLI if not already present
#   3. Generates wp-config.php with DB credentials from env vars
#   4. Installs WordPress (creates admin user + tables)
#   5. Creates a second regular user
#   6. Starts php-fpm in the FOREGROUND as PID 1 (using exec)
#
# ⚠️  No passwords are hardcoded — everything comes from environment variables
# ⚠️  No tail -f, sleep infinity, or while true — just exec php-fpm
# ==============================================================================

WP_PATH="/var/www/html"

# ──────────────────────────────────────────────────────────────────────────────
# Step 1: Wait for MariaDB to be ready
# depends_on only waits for the container to START, not for MySQL to be READY
# ──────────────────────────────────────────────────────────────────────────────
echo "[Inception] ⏳ Waiting for MariaDB to be ready..."
while ! mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    sleep 1
done
echo "[Inception] ✔ MariaDB is ready!"

# ──────────────────────────────────────────────────────────────────────────────
# Step 2: Download and configure WordPress (only on first run)
# ──────────────────────────────────────────────────────────────────────────────
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    echo "[Inception] First run detected — setting up WordPress..."

    # Download WordPress core files
    wp core download --path="${WP_PATH}" --allow-root

    # Generate wp-config.php with database credentials from environment
    wp config create \
        --path="${WP_PATH}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    # Install WordPress (create database tables, set site title, create admin user)
    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Create a second regular user (non-admin, role: author)
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --path="${WP_PATH}" \
        --allow-root

    # Set correct file ownership for the web server
    chown -R www-data:www-data "${WP_PATH}"

    echo "[Inception] ✔ WordPress installed successfully!"
    echo "[Inception] ✔ Admin user: ${WP_ADMIN_USER}"
    echo "[Inception] ✔ Regular user: ${WP_USER}"
else
    echo "[Inception] WordPress already configured — skipping setup"
fi

# ──────────────────────────────────────────────────────────────────────────────
# Step 3: Start PHP-FPM in the FOREGROUND as PID 1
# -F = foreground mode (no daemonize)
# 'exec' replaces the shell process, so php-fpm becomes PID 1
# ──────────────────────────────────────────────────────────────────────────────
echo "[Inception] ▶ Starting PHP-FPM..."
exec php-fpm7.4 -F
