# 🐳 Inception — 10-Day Completion Plan (Target: 125/100)

**Deadline:** September 1, 2026 (10 days from Aug 22)
**Target Score:** 🏆 **125/100** (Mandatory 100 + All 5 Bonuses 25)
**Project:** Set up a dockerized infrastructure with NGINX, WordPress + php-fpm, and MariaDB on a Virtual Machine using Docker Compose — plus Redis, FTP, static site, Adminer, and Portainer for full bonus.

---

## Project Overview

You need to build a small infrastructure of 3 interconnected Docker containers on a **Virtual Machine**, from custom Dockerfiles (based on Alpine or Debian), orchestrated via `docker-compose.yml` and a root `Makefile`.

### Architecture at a Glance

```
Internet ──► [NGINX :443 (TLS)] ──► [WordPress + php-fpm :9000] ──► [MariaDB :3306]
                   │                          │                            │
                   │                     volume: wp_files            volume: wp_db
                   │                   /home/login/data/wordpress   /home/login/data/mariadb
                   │
              ONLY entry point (port 443, TLSv1.2/1.3)
```

---

## 📅 Day 1 — Learn: Virtualization & Docker Fundamentals

### What to Learn
- **Virtual Machines**: What they are, how to set up a VM (VirtualBox or UTM)
- **Docker basics**: Images vs Containers, Dockerfile syntax, `docker build`, `docker run`
- **PID 1 problem**: Why your container process must run as PID 1 (no `tail -f`, `sleep infinity`, `bash`)
- **Daemon processes**: Why NOT to use them inside containers — run processes in the foreground

### What to Do
- [ ] Install a VM (Debian or Ubuntu) — this is where your entire project will run
- [ ] Install Docker and Docker Compose inside the VM
- [ ] Run your first container: `docker run -it debian:bullseye bash`
- [ ] Write a trivial Dockerfile (e.g., an nginx hello-world) and build/run it
- [ ] Practice basic docker commands: `docker ps`, `docker logs`, `docker exec`, `docker stop`, `docker rm`

### Resources
- [Docker Get Started](https://docs.docker.com/get-started/)
- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [PID 1 Signal Handling](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)

---

## 📅 Day 2 — Learn: Docker Compose, Networking & Volumes

### What to Learn
- **Docker Compose**: `docker-compose.yml` syntax, services, `build:`, `depends_on:`, `restart:`
- **Docker Networks**: Bridge networks, how containers communicate by service name (DNS)
- **Docker Volumes**: Named volumes vs bind mounts (you MUST use named volumes)
- **Volume driver options**: How to specify `device` option to mount volumes at `/home/login/data/`
- **Why `network: host`, `--link`, and `links:` are forbidden**

### What to Do
- [ ] Write a minimal `docker-compose.yml` with 2 services on a custom network
- [ ] Verify containers can communicate via service names (`ping wordpress` from nginx container)
- [ ] Create a named volume and inspect where data is stored
- [ ] Experiment with `restart: on-failure` / `restart: unless-stopped`
- [ ] Understand the `driver_opts` approach to map named volumes to `/home/login/data/`

### Resources
- [Docker Compose docs](https://docs.docker.com/compose/)
- [Docker Networking overview](https://docs.docker.com/network/)
- [Docker Volumes docs](https://docs.docker.com/storage/volumes/)

---

## 📅 Day 3 — Learn: MariaDB + Build the MariaDB Container

### What to Learn
- **MariaDB basics**: What it is, how it stores databases, config files (`/etc/mysql/mariadb.conf.d/`)
- **Initializing a DB in Docker**: Using `mysql_install_db` or `mariadb-install-db`, then starting with `mysqld_safe` or `mariadbd`
- **Creating users and databases**: SQL commands (`CREATE DATABASE`, `CREATE USER`, `GRANT`)
- **Entrypoint scripts**: Writing a shell script that initializes the DB, creates users, and then `exec`s the server process

### What to Do
- [ ] Create directory: `srcs/requirements/mariadb/`
- [ ] Write `Dockerfile` — base on `debian:bullseye` (or `alpine:3.18`)
- [ ] Write an entrypoint script (`tools/setup.sh`) that:
  - Initializes the database if not already initialized
  - Creates the WordPress database and user from environment variables
  - Starts `mariadbd` in the **foreground** (PID 1) using `exec`
- [ ] Write a MariaDB config file (`conf/50-server.cnf`) to bind on `0.0.0.0:3306`
- [ ] Test: build and run the container, connect with `mysql` client to verify DB exists

> [!IMPORTANT]
> **No passwords in Dockerfiles!** Use environment variables passed via `.env` or Docker secrets.

---

## 📅 Day 4 — Learn: WordPress + PHP-FPM & Build the WordPress Container

### What to Learn
- **PHP-FPM**: What it is (FastCGI Process Manager), how it listens on port 9000
- **WordPress**: How `wp-config.php` connects to the database, WP-CLI for automated setup
- **WP-CLI**: Command-line tool to download, install, and configure WordPress without a browser
- **Why no NGINX in this container** — WordPress only serves via php-fpm, NGINX reverse-proxies to it

### What to Do
- [ ] Create directory: `srcs/requirements/wordpress/`
- [ ] Write `Dockerfile`:
  - Install `php`, `php-fpm`, `php-mysql`, `php-curl`, `php-gd`, etc.
  - Install WP-CLI
  - Configure php-fpm to listen on `0.0.0.0:9000` (not a Unix socket)
- [ ] Write an entrypoint script (`tools/setup.sh`) that:
  - Downloads WordPress via WP-CLI if not already present
  - Generates `wp-config.php` with DB credentials from env vars
  - Installs WordPress (`wp core install`) with site title, admin user
  - Creates a second (non-admin) user
  - Starts `php-fpm` in the **foreground** using `exec php-fpmXX -F`
- [ ] Test: build and run alongside MariaDB, verify WP connects to the DB

> [!WARNING]
> The admin username **cannot** contain `admin`/`Admin`/`administrator`/`Administrator`. Use something like `superuser`, `boss`, or `webmaster`.

---

## 📅 Day 5 — Learn: NGINX + TLS & Build the NGINX Container

### What to Learn
- **NGINX**: Reverse proxy configuration, `server` blocks, `location` blocks
- **TLS/SSL**: What TLSv1.2 and TLSv1.3 are, self-signed certificates
- **OpenSSL**: How to generate a self-signed certificate (`openssl req -x509`)
- **FastCGI proxy**: How NGINX passes requests to php-fpm (`fastcgi_pass wordpress:9000`)

### What to Do
- [ ] Create directory: `srcs/requirements/nginx/`
- [ ] Write `Dockerfile`:
  - Install `nginx` and `openssl`
  - Generate a self-signed SSL certificate during build (or in entrypoint)
  - Copy NGINX config file
- [ ] Write NGINX config (`conf/nginx.conf`):
  - Listen on port `443 ssl` only
  - Set `ssl_protocols TLSv1.2 TLSv1.3;`
  - Set `ssl_certificate` and `ssl_certificate_key`
  - Proxy PHP requests to `wordpress:9000` via `fastcgi_pass`
  - Set `root` to WordPress files volume
  - Set `index index.php`
- [ ] Test: build and run, access `https://login.42.fr` in browser (expect certificate warning for self-signed)

---

## 📅 Day 6 — Integration: Wire Everything Together

### What to Do
- [ ] Write the complete `srcs/docker-compose.yml`:
  ```yaml
  services:
    nginx:      # builds from srcs/requirements/nginx/Dockerfile
    wordpress:  # builds from srcs/requirements/wordpress/Dockerfile
    mariadb:    # builds from srcs/requirements/mariadb/Dockerfile
  volumes:
    wp_data:    # WordPress files → /home/login/data/wordpress
    db_data:    # MariaDB data → /home/login/data/mariadb
  networks:
    inception:  # custom bridge network
  ```
- [ ] Create `srcs/.env` with all environment variables:
  ```
  DOMAIN_NAME=login.42.fr
  MYSQL_ROOT_PASSWORD=xxx       # or use secrets
  MYSQL_USER=xxx
  MYSQL_PASSWORD=xxx
  MYSQL_DATABASE=wordpress
  WP_ADMIN_USER=superuser
  WP_ADMIN_PASSWORD=xxx
  WP_ADMIN_EMAIL=xxx@xxx.com
  WP_USER=regular_user
  WP_USER_PASSWORD=xxx
  WP_USER_EMAIL=user@xxx.com
  ```
- [ ] Set up Docker secrets (create `secrets/` directory with password files)
- [ ] Write the root `Makefile`:
  ```makefile
  all:    # docker compose -f srcs/docker-compose.yml up --build -d
  down:   # docker compose down
  clean:  # remove volumes, images, containers
  fclean: # clean + remove /home/login/data/*
  re:     # fclean + all
  ```
- [ ] Configure `/etc/hosts` on the VM: `127.0.0.1 login.42.fr`
- [ ] Create the data directories: `mkdir -p /home/login/data/wordpress /home/login/data/mariadb`
- [ ] Run `make` and test the full stack

---

## 📅 Day 7 — Debug, Fix & Harden

### What to Do
- [ ] **Test the full flow end-to-end:**
  - `make` → all containers start cleanly
  - Open `https://login.42.fr` → WordPress site loads
  - Log in to WP admin panel → admin user works
  - Verify second user exists
- [ ] **Test crash recovery:** `docker kill <container>` → container restarts automatically
- [ ] **Test persistence:** `make down` then `make` → WordPress data still exists
- [ ] **Test clean rebuild:** `make fclean` then `make` → fresh install works
- [ ] **Verify no forbidden patterns:**
  - No `tail -f`, `sleep infinity`, `while true` in any entrypoint
  - No `network: host`, `--link`, or `links:` in compose
  - No `latest` tag on any image
  - No passwords in Dockerfiles
  - No bind mounts (only named volumes)
  - Admin username doesn't contain "admin"
- [ ] **Check TLS:** `curl -vk https://login.42.fr` → verify TLSv1.2 or TLSv1.3
- [ ] **Fix any issues found**

---

## 📅 Day 8 — Documentation: README, USER_DOC, DEV_DOC

### What to Do
- [ ] Write `README.md`:
  - First line: *This project has been created as part of the 42 curriculum by \<login\>.*
  - **Description**: Project goal and overview
  - **Project Description** with comparisons:
    - Virtual Machines vs Docker
    - Secrets vs Environment Variables
    - Docker Network vs Host Network
    - Docker Volumes vs Bind Mounts
  - **Instructions**: How to compile/install/run
  - **Resources**: Documentation links + AI usage disclosure
- [ ] Write `USER_DOC.md`:
  - What services are provided
  - How to start/stop the project
  - How to access the website and admin panel
  - Where credentials are located
  - How to check services are running
- [ ] Write `DEV_DOC.md`:
  - Environment setup from scratch
  - Build & launch with Makefile and Docker Compose
  - Container/volume management commands
  - Data storage locations and persistence

---

## 📅 Day 9 — Bonus Part (ALL 5 for 125/100) 🏆

> [!IMPORTANT]
> Bonuses are only evaluated if the mandatory part is **perfect**. Make sure Day 7 testing passed with zero issues before starting these. But we ARE doing all 5 to hit **125**.

### Bonus 1: Redis Cache ⚡
- [ ] Create `srcs/requirements/bonus/redis/`
- [ ] Write `Dockerfile` — install Redis on Debian/Alpine
- [ ] Configure Redis to listen on port `6379`, run `redis-server` in foreground with `exec`
- [ ] In WordPress container: install the **Redis Object Cache** plugin via WP-CLI
- [ ] Add `WP_REDIS_HOST=redis` and `WP_REDIS_PORT=6379` to `wp-config.php`
- [ ] Add `redis` service to `docker-compose.yml` on the `inception` network
- [ ] Test: verify cache is active in WP admin → Settings → Redis

### Bonus 2: FTP Server 📁
- [ ] Create `srcs/requirements/bonus/ftp/`
- [ ] Write `Dockerfile` — install `vsftpd`
- [ ] Configure vsftpd:
  - Passive mode with a port range (e.g., `21100-21110`)
  - Point to the WordPress volume (`/var/www/html`)
  - Create an FTP user from environment variables
  - Run `vsftpd` in foreground
- [ ] Expose ports `21` and `21100-21110` in `docker-compose.yml`
- [ ] Share the `wp_data` volume with this container
- [ ] Test: connect with an FTP client (`ftp login.42.fr`) and verify you see WordPress files

### Bonus 3: Static Website 🌐
- [ ] Create `srcs/requirements/bonus/static-site/`
- [ ] Write a simple **HTML/CSS/JS** site (e.g., a personal portfolio or resume page)
- [ ] **NO PHP allowed** — the subject explicitly bans it for this bonus
- [ ] Write `Dockerfile` — install a lightweight HTTP server (e.g., `nginx` or `python3 -m http.server`)
- [ ] Serve the static files, run server in foreground
- [ ] Expose on a separate port (e.g., `8080`) in `docker-compose.yml`
- [ ] Test: access `https://login.42.fr:8080` (or proxy through NGINX on a different path)

### Bonus 4: Adminer 🗄️
- [ ] Create `srcs/requirements/bonus/adminer/`
- [ ] Write `Dockerfile` — install Adminer (it's a single PHP file + php built-in server)
- [ ] Run with `php -S 0.0.0.0:8081 -t /var/www/adminer` in foreground
- [ ] Expose port `8081` in `docker-compose.yml`
- [ ] Connect to the `inception` network so it can reach MariaDB
- [ ] Test: access Adminer in browser → log in to MariaDB → see WordPress database

### Bonus 5: Portainer (Custom Service — Easy Pick) 🐋
- [ ] Create `srcs/requirements/bonus/portainer/`
- [ ] Write `Dockerfile` — download and install the Portainer CE binary
- [ ] Run Portainer in foreground, expose port `9443`
- [ ] Mount the Docker socket (`/var/run/docker.sock`) so Portainer can manage containers
- [ ] Give it its own named volume for Portainer data
- [ ] Test: access `https://login.42.fr:9443` → see all your Inception containers in a dashboard

> [!TIP]
> **Why Portainer?** It's the easiest to justify during defense: *"I chose Portainer because it provides a web-based UI to monitor and manage all Docker containers in the infrastructure, which is essential for system administration — the core theme of this project."* Evaluators love it because it's practical and directly relevant.

### For each bonus service:
- ✅ Write a **dedicated Dockerfile** (no pre-made images)
- ✅ Each runs in its **own container**
- ✅ Each has its own **volume** if it needs persistent data
- ✅ Add to `docker-compose.yml` on the `inception` network
- ✅ Use the same base image strategy (penultimate stable Debian/Alpine, no `latest`)

---

## 📅 Day 10 — Final Review, Cleanup & Submission

### What to Do
- [ ] **Full clean test:** `make fclean && make` — everything works from scratch
- [ ] **Directory structure check:** Verify it matches the subject's expected layout:
  ```
  .
  ├── Makefile
  ├── secrets/
  │   ├── credentials.txt
  │   ├── db_password.txt
  │   └── db_root_password.txt
  └── srcs/
      ├── .env
      ├── docker-compose.yml
      └── requirements/
          ├── mariadb/
          │   ├── Dockerfile
          │   ├── conf/
          │   └── tools/
          ├── nginx/
          │   ├── Dockerfile
          │   ├── conf/
          │   └── tools/
          ├── wordpress/
          │   ├── Dockerfile
          │   ├── conf/
          │   └── tools/
          └── bonus/ (if applicable)
  ```
- [ ] **Git hygiene:**
  - `.gitignore` includes `.env`, `secrets/`, and any sensitive files
  - No passwords/credentials committed
  - Clean commit history
- [ ] **Prepare for defense:**
  - Be ready to explain every line of every Dockerfile
  - Understand Docker networking, volumes, TLS
  - Know the difference between VM vs Docker, secrets vs env vars
  - Be prepared for a "live modification" request (e.g., add a small feature or change)
- [ ] **Push to Git repository**

---

## 🚫 FORBIDDEN THINGS — Instant Failure List

Read this section carefully. **Any single violation = project failure.** Check every item before submission.

---

### 🔴 Dockerfile & Image Violations

| ❌ Forbidden | ✅ What to Do Instead | Why It Fails |
|---|---|---|
| Pulling pre-made Docker images (e.g., `FROM wordpress`, `FROM nginx`, `FROM mariadb`) | Write your own Dockerfile starting from `FROM debian:bullseye` or `FROM alpine:3.18` | Subject says you must **build** your own images |
| Using `latest` tag (`FROM debian:latest`) | Use a **specific version**: `FROM debian:bullseye` or `FROM alpine:3.18` | "The latest tag is prohibited" |
| Using an image that is NOT the **penultimate stable** version | Check Alpine/Debian release pages for the second-to-latest stable | Subject says "penultimate stable version" |
| Passwords or secrets hardcoded in Dockerfiles (`ENV MYSQL_PASSWORD=mypass123`) | Pass via `.env` file, `environment:` in compose, or Docker secrets | "No password must be present in your Dockerfiles" |
| Using DockerHub services (pulling pre-built images) | Only Alpine/Debian base images are allowed from DockerHub | Explicitly forbidden in subject |

---

### 🔴 Entrypoint & Process Violations

| ❌ Forbidden | ✅ What to Do Instead | Why It Fails |
|---|---|---|
| `tail -f /dev/null` or `tail -f` anything | Run the actual service process in foreground | "Hacky patch" — explicitly banned |
| `sleep infinity` | Run service with `exec` as PID 1 | Explicitly listed as prohibited |
| `while true; do ... done` | Service must run natively in foreground | Infinite loop — explicitly banned |
| `bash` as entrypoint/CMD | Use `exec <service>` as the final command | Explicitly banned |
| `CMD ["/bin/bash"]` or `ENTRYPOINT ["/bin/bash"]` | `CMD ["your-setup-script.sh"]` which ends with `exec <service>` | Container must run a real service |
| Running daemons in background (`service nginx start`) | Run process in **foreground**: `nginx -g 'daemon off;'` | Container exits immediately if process backgrounds |

---

### 🔴 Networking Violations

| ❌ Forbidden | ✅ What to Do Instead | Why It Fails |
|---|---|---|
| `network_mode: host` or `network: host` | Use a custom bridge network defined in compose | Explicitly forbidden |
| `--link` flag | Use Docker Compose service names (DNS-based discovery) | Deprecated and explicitly forbidden |
| `links:` in docker-compose.yml | Use a shared `networks:` section | Explicitly forbidden |
| Missing `networks:` in docker-compose.yml | Define a custom network (e.g., `inception`) and attach all services | "The network line must be present" |
| Exposing any port other than 443 from NGINX to the outside | NGINX listens on `443` only with TLS | "NGINX must be the only entrypoint via port 443 only" |
| Using HTTP (port 80) | NGINX must use HTTPS with TLSv1.2 or TLSv1.3 | Only TLS connections allowed |

---

### 🔴 Volume & Storage Violations

| ❌ Forbidden | ✅ What to Do Instead | Why It Fails |
|---|---|---|
| Bind mounts (`./data:/var/lib/mysql`) | Use Docker **named volumes** with `driver_opts` to point to `/home/login/data/` | "Bind mounts are not allowed for these volumes" |
| Named volumes storing data anywhere other than `/home/login/data/` | Configure `driver_opts` with `device: /home/login/data/wordpress` (or mariadb) | Subject requires this specific path |
| Not using named volumes for WP database and WP files | Define two named volumes in the `volumes:` section of compose | "You must use Docker named volumes" |

---

### 🔴 Security & Credentials Violations

| ❌ Forbidden | ✅ What to Do Instead | Why It Fails |
|---|---|---|
| Passwords in Dockerfiles | Use `.env` file + `environment:` in compose, or Docker secrets | Explicitly forbidden |
| API keys / passwords committed to Git | Add `.env`, `secrets/` to `.gitignore` | "Publicly stored credentials will lead to failure" |
| Not using environment variables | Store config in `.env`, reference with `${VAR}` in compose | "It is mandatory to use environment variables" |
| Not using a `.env` file | Create `srcs/.env` with all variables | "It is mandatory to use a .env file" |
| Credentials, API keys, or passwords found in Git repo (outside of secrets) | Use Docker secrets or `.env` excluded from git | "Will result in project failure" |

---

### 🔴 WordPress Violations

| ❌ Forbidden | ✅ What to Do Instead | Why It Fails |
|---|---|---|
| Admin username containing `admin` (any case) | Use `superuser`, `boss`, `webmaster`, etc. | Explicitly forbidden: `admin`, `Admin`, `administrator`, `Administrator`, `admin-123`, etc. |
| Admin username containing `administrator` (any case) | Same as above | Same rule |
| Only 1 user in the database | Create 2 users: 1 admin + 1 regular user | "There must be two users" |
| NGINX inside the WordPress container | WordPress container runs **only** php-fpm | "WordPress + php-fpm only, without nginx" |
| NGINX inside the MariaDB container | MariaDB container runs **only** MariaDB | "MariaDB only, without nginx" |

---

### 🔴 Infrastructure & Container Violations

| ❌ Forbidden | ✅ What to Do Instead | Why It Fails |
|---|---|---|
| Not running on a Virtual Machine | Set up VirtualBox/UTM VM for the whole project | "This project needs to be done on a Virtual Machine" |
| Multiple services in one container | One service = one container = one Dockerfile | "Each service has to run in a dedicated container" |
| Docker image name ≠ service name | Name images the same as their compose service | "Each Docker image must have the same name as its corresponding service" |
| No `restart` policy | Add `restart: on-failure` or `restart: unless-stopped` to every service | "Your containers have to restart in case of a crash" |
| Config files outside `srcs/` folder | Put everything in `srcs/` (except Makefile and secrets at root) | "All files required for configuration must be placed in a srcs folder" |
| No Makefile at project root | Create a Makefile that calls `docker compose` | "A Makefile is also required at the root" |
| Domain name not configured | Add `127.0.0.1 login.42.fr` to `/etc/hosts` | "Configure your domain name to point to your local IP" |

---

### 🔴 Documentation Violations

| ❌ Forbidden (Missing) | What's Required |
|---|---|
| No `README.md` | Must include: italicized first line, Description, Instructions, Resources (with AI usage), Project Description with 4 comparisons |
| No `USER_DOC.md` | Must explain: services, start/stop, access website/admin, credentials, health checks |
| No `DEV_DOC.md` | Must explain: env setup, build/launch, container/volume commands, data storage |
| README not in English | "Your README must be written in English" |
| Missing 4 comparisons in README | Must compare: VM vs Docker, Secrets vs Env Vars, Docker Network vs Host Network, Volumes vs Bind Mounts |

---

### 🔴 Bonus-Specific Violations

| ❌ Forbidden | ✅ What to Do Instead |
|---|---|
| Using PHP for the static website bonus | Use HTML/CSS/JS, Python, Go, or any language **except PHP** |
| No dedicated Dockerfile for a bonus service | Each bonus service needs its own Dockerfile |
| Bonus service not in its own container | Each bonus = its own container |
| Attempting bonus when mandatory part has bugs | Fix mandatory first — "bonus will not be evaluated if mandatory is not perfect" |

---

## ✅ Key Rules Checklist (Check Before Submission)

| # | Rule | Status |
|---|------|--------|
| 1 | Everything runs on a Virtual Machine | ☐ |
| 2 | All config files in `srcs/` folder | ☐ |
| 3 | Root `Makefile` builds everything with `docker compose` | ☐ |
| 4 | Custom Dockerfiles — no pulling pre-made images (except Alpine/Debian base) | ☐ |
| 5 | No `latest` tag anywhere | ☐ |
| 6 | Base image: **penultimate** stable Alpine or Debian | ☐ |
| 7 | One service per container | ☐ |
| 8 | Docker image name = service name | ☐ |
| 9 | NGINX is the ONLY entrypoint (port 443, TLSv1.2/TLSv1.3 only) | ☐ |
| 10 | No `network: host`, `--link`, `links:` | ☐ |
| 11 | Custom `networks:` defined in docker-compose.yml | ☐ |
| 12 | No `tail -f`, `sleep infinity`, `while true`, `bash` as entrypoint | ☐ |
| 13 | All processes run in foreground as PID 1 (using `exec`) | ☐ |
| 14 | Named volumes only (no bind mounts) stored at `/home/login/data/` | ☐ |
| 15 | No passwords in Dockerfiles | ☐ |
| 16 | `.env` file used for environment variables | ☐ |
| 17 | Docker secrets used for sensitive data | ☐ |
| 18 | `.env` and `secrets/` NOT committed to git | ☐ |
| 19 | `restart` policy on all containers | ☐ |
| 20 | Domain `login.42.fr` resolves to local IP | ☐ |
| 21 | WP has 2 users, admin username has NO "admin" variant | ☐ |
| 22 | README.md with all required sections (English, 4 comparisons) | ☐ |
| 23 | USER_DOC.md present with all required content | ☐ |
| 24 | DEV_DOC.md present with all required content | ☐ |
| 25 | Static website bonus does NOT use PHP | ☐ |
| 26 | All 5 bonus services have dedicated Dockerfiles + containers | ☐ |
| 27 | `make fclean && make` works from scratch | ☐ |
| 28 | `docker kill` → container auto-restarts | ☐ |
| 29 | Data persists after `make down && make` | ☐ |
| 30 | No credentials/API keys in Git history | ☐ |

---

## 📊 Daily Time Estimate

| Day | Focus | Est. Hours |
|-----|-------|-----------|
| 1 | VM Setup + Docker Fundamentals | 3-4h |
| 2 | Docker Compose, Networks, Volumes | 3-4h |
| 3 | MariaDB Container | 4-5h |
| 4 | WordPress + PHP-FPM Container | 5-6h |
| 5 | NGINX + TLS Container | 4-5h |
| 6 | Integration (wire everything) | 5-6h |
| 7 | Debug, Fix & Harden | 4-5h |
| 8 | Documentation (README, USER_DOC, DEV_DOC) | 3-4h |
| 9 | ALL 5 Bonus services (Redis, FTP, Static, Adminer, Portainer) | 6-8h |
| 10 | Final review, bonus testing & submission | 3-4h |

> [!TIP]
> Days 4 and 6 are the hardest for mandatory. Day 9 is the longest day — start early. If you're behind on mandatory, use Day 9 morning for fixes, then bonuses in the afternoon.
