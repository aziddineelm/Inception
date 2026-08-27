FROM debian:bullseye

RUN apt-get update -y && \
    apt-get install -y nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY src/ /var/www/static/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
