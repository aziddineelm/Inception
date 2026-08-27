#!/bin/bash

# Create secure chroot directory required by vsftpd
mkdir -p /var/run/vsftpd/empty

# Create FTP user if not already existing
if ! id "${FTP_USER}" &>/dev/null; then
    echo "Creating FTP user '${FTP_USER}'..."
    useradd -m -s /bin/bash "${FTP_USER}"
    echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

# Ensure correct permissions for WordPress files
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html
usermod -aG www-data "${FTP_USER}"

# Start vsftpd in foreground
echo "Starting vsftpd..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
