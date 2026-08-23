FROM debian:bullseye

# Install MariaDB server and client
RUN apt-get update -y && \
    apt-get install -y mariadb-server mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy custom MariaDB config
COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/mariadb.cnf

# Copy entrypoint script and make it executable
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Run setup script which ends with exec mysqld (PID 1, foreground)
ENTRYPOINT ["/usr/local/bin/setup.sh"]
