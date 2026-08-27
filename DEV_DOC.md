# Developer Documentation

This documentation provides technical guidelines for developers to set up, build, manage, and understand the Inception infrastructure.

---

## 1. Setting Up the Environment from Scratch

### Prerequisites
* Operating System: Linux Virtual Machine (Debian 11+ or Ubuntu 20.04+)
* Docker Engine 20.10+ and Docker Compose v2+
* GNU Make and curl

### Step 1: Configure Local Domain
Add local domain resolution to `/etc/hosts`:
```bash
echo "127.0.0.1 ael-mans.42.fr" | sudo tee -a /etc/hosts
```

### Step 2: Configure Environment Variables & Secrets
Create the `srcs/.env` file:
```bash
# Domain configuration
DOMAIN_NAME=ael-mans.42.fr

# MariaDB credentials
MYSQL_DATABASE=wordpress
MYSQL_USER=your_db_user
MYSQL_PASSWORD=your_db_password
MYSQL_ROOT_PASSWORD=your_root_password

# WordPress configuration
WP_TITLE=Inception
# (Admin username MUST NOT contain 'admin' or 'administrator')
WP_ADMIN_USER=your_admin_user
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=your_admin_email@domain.com
WP_USER=your_regular_user
WP_USER_PASSWORD=your_user_password
WP_USER_EMAIL=your_user_email@domain.com

# FTP Server credentials (Bonus)
FTP_USER=your_ftp_user
FTP_PASSWORD=your_ftp_password
```

### Step 3: Directory Structure
```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
└── srcs/
    ├── .env
    ├── docker-compose.yaml
    ├── docker-compose-bonus.yaml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/mariadb.cnf
        │   └── tools/setup.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/setup.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/setup.sh
        └── bonus/
            ├── adminer/
            │   ├── Dockerfile
            │   └── tools/setup.sh
            ├── ftp/
            │   ├── Dockerfile
            │   ├── conf/vsftpd.conf
            │   └── tools/setup.sh
            ├── portainer/
            │   └── Dockerfile
            ├── redis/
            │   ├── Dockerfile
            │   └── conf/redis.conf
            └── static-site/
                ├── Dockerfile
                ├── conf/nginx.conf
                └── src/
```

---

## 2. Building and Launching the Project

The stack is orchestrated using `Makefile` and Docker Compose:
* `srcs/docker-compose.yaml`: Defines mandatory services (`nginx`, `wordpress`, `mariadb`).
* `srcs/docker-compose-bonus.yaml`: Extends the stack with bonus services (`redis`, `ftp`, `static-site`, `adminer`, `portainer`).

### Build & Launch Commands:
```bash
# Build and launch mandatory containers in background:
make

# Build and launch mandatory + all bonus containers:
make bonus

# Stop all containers:
make down

# Clean containers, networks, and images:
make clean

# Full clean (removes containers, images, and host data):
make fclean

# Rebuild from scratch:
make re
```

---

## 3. Relevant Commands to Manage Containers and Volumes

### Container Inspection
```bash
# List all running containers:
docker ps

# Inspect running processes inside containers (PID 1 verification):
docker top nginx
docker top wordpress
docker top mariadb

# View logs:
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Network Inspection
```bash
# Inspect the custom bridge network:
docker network inspect srcs_inception
```

### Shell Access for Debugging
```bash
# Access WordPress container shell:
docker exec -it wordpress bash

# Access MariaDB container shell:
docker exec -it mariadb bash

# Execute WP-CLI commands inside WordPress container:
docker exec -it wordpress wp --allow-root --path=/var/www/html <command>
```

---

## 4. Data Storage and Persistence

### Storage Locations on Host
Data is stored directly on the host machine in `/home/ael-mans/data/`:
* **WordPress Website Files:** `/home/ael-mans/data/wordpress`
* **MariaDB Database Data:** `/home/ael-mans/data/mariadb`
* **Portainer Data:** `/home/ael-mans/data/portainer`

### Named Volume Driver Configuration
To comply with the subject rule requiring Docker named volumes (and forbidding raw bind mounts in volume declarations), the project uses named volumes configured with local bind `driver_opts`:

```yaml
volumes:
  wp_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ael-mans/data/wordpress

  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ael-mans/data/mariadb

  portainer_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/ael-mans/data/portainer
```

This ensures Docker manages volume lifecycle metadata while guaranteeing that data persists across container recreations and restarts.
