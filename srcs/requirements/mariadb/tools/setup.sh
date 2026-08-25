#!/bin/bash

# Create runtime directories needed by MariaDB
mkdir -p /var/run/mysqld
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/log/mysql
chown -R mysql:mysql /var/lib/mysql

# Only run database initialization on the first container startup
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "First run: initializing MariaDB database..."

    # Install base system tables
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Run mysqld in bootstrap mode to execute initial SQL setup commands
    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;

-- Delete anonymous users for security
DELETE FROM user WHERE User='';

-- Set password for root user on localhost
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create the WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create the user and grant access from any host (%) on the Docker network
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    echo "Database '${MYSQL_DATABASE}' and user '${MYSQL_USER}' created."
fi

# Start MariaDB in foreground as PID 1
echo "Starting MariaDB..."
exec mysqld --user=mysql
