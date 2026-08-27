FROM debian:bullseye

RUN apt-get update -y && \
    apt-get install -y php7.4-cli php7.4-mysql curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 8081

ENTRYPOINT ["/usr/local/bin/setup.sh"]
