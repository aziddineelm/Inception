# User Documentation

This guide explains how an end user or administrator can operate and manage the Inception infrastructure.

---

## 1. Services Provided by the Stack

| Service | Description | Access URL / Port |
|---|---|---|
| **NGINX** | Secure TLS reverse proxy (entrypoint) | `https://ael-mans.42.fr` (Port 443) |
| **WordPress** | Website content management system | `https://ael-mans.42.fr` |
| **WP Admin** | WordPress administration dashboard | `https://ael-mans.42.fr/wp-admin` |
| **MariaDB** | Database backend | Internal port 3306 (Docker network only) |
| **Redis** | In-memory cache for WordPress | Internal port 6379 (Docker network only) |
| **FTP Server** | File transfer server for WordPress files | `ftp://ael-mans.42.fr:21` (Passive: 21100) |
| **Static Website** | Personal portfolio / showcase site | `http://ael-mans.42.fr:8080` |
| **Adminer** | Database management web interface | `http://ael-mans.42.fr:8081` |
| **Portainer** | Container management web dashboard | `https://ael-mans.42.fr:9443` |

---

## 2. Starting and Stopping the Project

All service management is executed using the root `Makefile`:

### Start Services
```bash
# Start mandatory services only (NGINX, WordPress, MariaDB):
make

# Start mandatory + all bonus services:
make bonus
```

### Stop Services
```bash
# Stop running containers without deleting data:
make down
```

### Clean & Reset
```bash
# Clean containers, images, and networks:
make clean

# Full reset (removes everything including persistent data on host):
make fclean

# Rebuild from scratch:
make re
```

---

## 3. Accessing the Website and Administration Panels

* **WordPress Website:** Open your browser and navigate to `https://ael-mans.42.fr`.
  *(Accept the self-signed SSL certificate warning if prompted).*
* **WordPress Admin Panel:** Navigate to `https://ael-mans.42.fr/wp-admin` and log in with your administrator credentials.
* **Adminer (Database Interface):** Navigate to `http://ael-mans.42.fr:8081` (System: `MySQL`, Server: `mariadb`, Username/Password from `.env`).
* **Portainer (Container Dashboard):** Navigate to `https://ael-mans.42.fr:9443` (set your admin password on first visit).
* **FTP Access:** Connect using any FTP client:
  ```bash
  ftp ael-mans.42.fr 21
  ```

---

## 4. Locating and Managing Credentials

Credentials and environment configuration are stored in `srcs/.env` (which is excluded from Git).

To configure credentials on a new setup, create `srcs/.env`:

```bash
# Domain
DOMAIN_NAME=ael-mans.42.fr

# MariaDB Credentials
MYSQL_DATABASE=wordpress
MYSQL_USER=your_db_user
MYSQL_PASSWORD=your_db_password
MYSQL_ROOT_PASSWORD=your_root_password

# WordPress Site Configuration
WP_TITLE=Inception

# WordPress Administrator Account
# Note: Username MUST NOT contain 'admin' or 'administrator'
WP_ADMIN_USER=your_admin_user
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=your_admin_email@domain.com

# WordPress Regular User Account
WP_USER=your_regular_user
WP_USER_PASSWORD=your_user_password
WP_USER_EMAIL=your_user_email@domain.com

# FTP Server Credentials (Bonus)
FTP_USER=your_ftp_user
FTP_PASSWORD=your_ftp_password
```

### Updating Credentials
To update credentials:
1. Edit the variables in `srcs/.env`.
2. Apply changes by running `make re` (or `make fclean && make bonus`).

---

## 5. Checking that Services are Running Correctly

### Check Container Status
```bash
docker ps -a
```
All containers should report a status of `Up`.

### Check Service Logs
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Check Endpoints via CLI
```bash
# Verify HTTPS WordPress (TLS):
curl -kv https://ael-mans.42.fr

# Verify Static Website:
curl -I http://ael-mans.42.fr:8080

# Verify Adminer:
curl -I http://ael-mans.42.fr:8081

# Verify Redis Cache:
docker exec redis redis-cli ping
# Expected: PONG
```
