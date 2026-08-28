#!/bin/bash

WP_PATH="/var/www/html"

# Wait until MariaDB is fully ready to accept connections
echo "Waiting for MariaDB..."
while ! mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    sleep 1
done
echo "MariaDB is ready."

# Only configure WordPress on first run (when wp-config.php does not exist)
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    echo "First run: downloading and configuring WordPress..."

    # Download WordPress core files
    wp core download --path="${WP_PATH}" --allow-root

    # Create wp-config.php with database credentials
    wp config create \
        --path="${WP_PATH}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    # Install WordPress and create the administrator user
    # Note: Admin username does not contain 'admin' as required by the subject
    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Create a second regular user (Author role)
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --path="${WP_PATH}" \
        --allow-root

    # Set web server permissions
    chown -R www-data:www-data "${WP_PATH}"

    echo "WordPress installation finished."
fi

# Configure Redis Object Cache if Redis is enabled (Bonus)
if redis-cli -h redis ping &> /dev/null; then
    if ! wp plugin is-installed redis-cache --path="${WP_PATH}" --allow-root 2>/dev/null; then
        wp config set WP_REDIS_HOST redis --path="${WP_PATH}" --allow-root
        wp config set WP_REDIS_PORT 6379 --raw --path="${WP_PATH}" --allow-root
        wp plugin install redis-cache --activate --path="${WP_PATH}" --allow-root
        wp redis enable --path="${WP_PATH}" --allow-root
    fi
fi

# Start PHP-FPM in foreground (PID 1) using -F flag
echo "Starting PHP-FPM..."
exec php-fpm7.4 -F
