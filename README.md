*This project has been created as part of the 42 curriculum by ael-mans.*

# Inception

## Description

**Inception** is a system administration project that introduces virtualization and containerization using **Docker** and **Docker Compose**. The goal is to design and deploy a secure, modular, and resilient multi-container infrastructure from scratch inside a personal Virtual Machine.

Every container runs a dedicated service, built from custom Dockerfiles based on the penultimate stable version of **Debian (`bullseye`)**, without relying on pre-made Docker Hub application images.

---

## Project Description & Architectural Choices

### 1. Virtual Machines vs Docker
* **Virtual Machines (VMs):** VMs virtualize the entire hardware layer (CPU, memory, disks, network interfaces) using a Hypervisor. Each VM runs a full-blown guest operating system with its own kernel, consuming significant CPU, memory, and disk overhead with slow startup times.
* **Docker (Containers):** Containers share the host Linux kernel and isolate processes using kernel features like **cgroups** (resource limits) and **namespaces** (PID, mount, network isolation). Containers are lightweight, start in seconds, and have near-native performance.
* **Why Docker in this project:** To achieve modular, microservice-based architecture where each service runs in an isolated environment with minimal resource consumption.

### 2. Secrets vs Environment Variables
* **Environment Variables (`.env`):** Great for general configuration (domain names, ports, non-sensitive parameters). However, they are visible to any process inside the container via `/proc` or `env` commands and can leak through error logs or child processes.
* **Docker Secrets:** Sensitive data (passwords, private keys, tokens) is stored securely in separate files or in-memory tmpfs mounts, read only by authorized containers at runtime without exposing credentials in environment listings.
* **In this project:** Credentials and passwords are kept out of Git repositories via `.gitignore` and `.env` / secret files to ensure security compliance.

### 3. Docker Network vs Host Network
* **Host Network (`network_mode: host`):** Bypasses Docker's network isolation; the container directly binds to the host's network interfaces and port space. This is insecure and breaks container portability (forbidden by subject).
* **Docker Bridge Network (User-Defined):** Creates an isolated software bridge network (`inception`) where containers can only communicate with each other using internal DNS resolution (service names like `mariadb:3306` or `wordpress:9000`). Only explicitly published ports (such as NGINX `:443`) are reachable from outside.

### 4. Docker Volumes vs Bind Mounts
* **Bind Mounts:** Directly map a specific file or directory from the host filesystem into a container. They depend on the host's directory structure and permissions, bypassing Docker volume lifecycle management.
* **Docker Named Volumes:** Managed directly by the Docker daemon. They decouple storage from container lifecycles, ensuring data persists across rebuilds.
* **In this project:** We use named volumes (`wp_data`, `db_data`, `portainer_data`) configured with local bind `driver_opts` to store data in `/home/ael-mans/data/`, combining Docker-managed volume tracking with host directory compliance.

---

## Services Included

### Mandatory Services
* **NGINX:** The single entrypoint to the web infrastructure via port 443 with TLSv1.2 / TLSv1.3 only.
* **WordPress + PHP-FPM:** WordPress core files with PHP FastCGI Process Manager listening on port 9000.
* **MariaDB:** Relational database server storing WordPress data.

### Bonus Services (125/100)
* **Redis Cache:** In-memory key-value cache configured as an Object Cache for WordPress queries.
* **FTP Server (`vsftpd`):** Secure FTP server on port 21 (passive: 21100) pointing to the WordPress directory.
* **Static Website:** Showcase/portfolio website built in pure HTML/CSS (**No PHP**), served on port 8080.
* **Adminer:** Web-based database management interface for MariaDB on port 8081.
* **Portainer (Custom Service):** Container monitoring and management dashboard on port 9443.

---

## Instructions

### Prerequisites
* Linux Virtual Machine (Debian / Ubuntu)
* Docker and Docker Compose (v2+)
* `make` and `curl`

### Installation & Launch

1. **Clone the repository:**
   ```bash
   git clone <repo-url> Inception && cd Inception
   ```

2. **Configure local domain in `/etc/hosts`:**
   ```bash
   echo "127.0.0.1 ael-mans.42.fr" | sudo tee -a /etc/hosts
   ```

3. **Create the environment configuration file (`srcs/.env`):**
   > **Note:** For security reasons, `.env` is ignored by Git. You must create `srcs/.env` before launching the stack:
   ```bash
   # Domain
   DOMAIN_NAME=ael-mans.42.fr

   # MariaDB
   MYSQL_DATABASE=wordpress
   MYSQL_USER=your_db_user
   MYSQL_PASSWORD=your_db_password
   MYSQL_ROOT_PASSWORD=your_root_password

   # WordPress Setup
   WP_TITLE=Inception
   # (Admin username MUST NOT contain 'admin' or 'administrator')
   WP_ADMIN_USER=your_admin_user
   WP_ADMIN_PASSWORD=your_admin_password
   WP_ADMIN_EMAIL=your_admin_email@domain.com
   WP_USER=your_regular_user
   WP_USER_PASSWORD=your_user_password
   WP_USER_EMAIL=your_user_email@domain.com

   # FTP Server (Bonus)
   FTP_USER=your_ftp_user
   FTP_PASSWORD=your_ftp_password
   ```

4. **Start the Mandatory Stack (NGINX, WordPress, MariaDB):**
   ```bash
   make
   ```

5. **Start BONUS Part (Mandatory + All 5 Bonus Services):**
   ```bash
   make bonus
   ```

### Management Commands

| Command | Description |
|---|---|
| `make` | Build and start the mandatory containers in detached mode |
| `make bonus` | Build and start mandatory + all 5 bonus containers |
| `make down` | Stop and remove running containers |
| `make clean` | Stop containers and remove images, networks, and volumes |
| `make fclean` | Full clean: removes all containers, images, volumes, and host data in `/home/ael-mans/data/` (requires `sudo` for data removal) |
| `make re` | Clean rebuild from scratch |

---

## Resources & AI Disclosure

### References & Documentation
* [Docker Official Documentation](https://docs.docker.com/)
* [Docker Compose Specification](https://docs.docker.com/compose/)
* [NGINX Documentation & TLS Configuration](https://nginx.org/en/docs/)
* [WP-CLI Command Reference](https://developer.wordpress.org/cli/commands/)
* [MariaDB Server Knowledge Base](https://mariadb.com/kb/en/)
* [vsftpd Configuration Manual](https://security.appspot.com/vsftpd/vsftpd_conf.html)

### AI Usage Disclosure
AI was used as a learning and research companion throughout this project for:
* **Understanding Project Requirements:** Breaking down the subject guidelines, constraints, and architecture.
* **Learning Core Concepts:** Asking for explanations of fundamental system administration and Docker topics (PID 1 process lifecycle, foreground execution vs background daemons, TLS protocols, and Docker networking).
* **Debugging Guidance:** Inquiring about configuration syntax and troubleshooting error codes during service integration.
