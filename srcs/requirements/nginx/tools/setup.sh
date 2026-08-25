#!/bin/bash

# Generate a self-signed SSL/TLS certificate for HTTPS
# -x509: create a self-signed certificate
# -nodes: do not encrypt the private key (no passphrase needed on boot)
# -subj: set the domain name (Common Name) for the certificate
if [ ! -f /etc/ssl/certs/nginx.crt ]; then
    echo "Generating self-signed SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -subj "/CN=${DOMAIN_NAME}"
fi

# Start NGINX in foreground (PID 1)
# 'daemon off' prevents NGINX from running in background so Docker doesn't exit
echo "Starting NGINX..."
exec nginx -g 'daemon off;'
