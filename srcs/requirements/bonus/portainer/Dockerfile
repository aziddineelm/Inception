FROM debian:bullseye

RUN apt-get update -y && \
    apt-get install -y curl tar ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz | tar -xzv -C /usr/local/bin/

EXPOSE 9443

CMD ["/usr/local/bin/portainer/portainer"]
