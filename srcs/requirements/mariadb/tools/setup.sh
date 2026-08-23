#!/bin/bash
# ==============================================================================
# MariaDB Entrypoint Script
# ==============================================================================
# This script:
#   1. Initializes the database if it doesn't exist yet
#   2. Creates the WordPress database and user
#   3. Starts MariaDB in the FOREGROUND as PID 1 (using exec)
#
# ⚠️  No passwords are hardcoded — everything comes from environment variables
# ⚠️  No tail -f, sleep infinity, or while true — just exec mysqld
# ==============================================================================

# Create required directories
mkdir -p /var/run/mysqld
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/log/mysql
chown -R mysql:mysql /var/lib/mysql
chmod 777 /var/run/mysqld

# ──────────────────────────────────────────────────────────────────────────────
# Only initialize if the database doesn't exist yet (first run)
# ──────────────────────────────────────────────────────────────────────────────
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "[Inception] First run detected — initializing MariaDB..."

    # Initialize the system database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start a temporary MariaDB server to set up users and databases
    mysqld --user=mysql --bootstrap << EOF
-- Switch to the mysql system database
USE mysql;
FLUSH PRIVILEGES;

-- Delete anonymous users (security)
DELETE FROM user WHERE User='';

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create the WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Create the WordPress user with access from any host (containers use different IPs)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    echo "[Inception] ✔ Database '${MYSQL_DATABASE}' created"
    echo "[Inception] ✔ User '${MYSQL_USER}' created with full privileges"
else
    echo "[Inception] Database already exists — skipping initialization"
fi

# ──────────────────────────────────────────────────────────────────────────────
# Start MariaDB in the FOREGROUND as PID 1
# 'exec' replaces the shell process, so mysqld becomes PID 1
# ──────────────────────────────────────────────────────────────────────────────
echo "[Inception] ▶︎ Starting MariaDB..."
exec mysqld --user=mysql
