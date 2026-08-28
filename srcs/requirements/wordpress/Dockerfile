FROM debian:bullseye

# Install PHP-FPM and all required extensions for WordPress
RUN apt-get update -y && \
    apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-zip \
    php7.4-intl \
    php-redis \
    redis-tools \
    mariadb-client \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI (command-line tool to manage WordPress)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM pool config (listen on TCP 9000 instead of Unix socket)
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy entrypoint script
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

RUN mkdir -p /run/php

ENTRYPOINT ["/usr/local/bin/setup.sh"]
