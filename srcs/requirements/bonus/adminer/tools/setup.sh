#!/bin/bash

mkdir -p /var/www/html

# Download Adminer single PHP file if not already downloaded
if [ ! -f /var/www/html/index.php ]; then
    echo "Downloading Adminer..."
    curl -L https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php -o /var/www/html/index.php
fi

# Start PHP built-in web server in foreground on port 8081
echo "Starting Adminer on port 8081..."
exec php -S 0.0.0.0:8081 -t /var/www/html
