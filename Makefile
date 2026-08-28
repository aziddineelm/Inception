DATA_DIR       = /home/ael-mans/data
COMPOSE        = docker compose -f srcs/docker-compose.yaml
COMPOSE_BONUS  = docker compose -f srcs/docker-compose.yaml -f srcs/docker-compose-bonus.yaml

GREEN  = \033[0;32m
RED    = \033[0;31m
YELLOW = \033[0;33m
RESET  = \033[0m

# Build and start mandatory containers (nginx, wordpress, mariadb)
all: setup
	@echo "$(GREEN)Starting mandatory containers...$(RESET)"
	$(COMPOSE) up --build -d
	@echo "$(GREEN)Mandatory stack is ready.$(RESET)"

# Build and start mandatory + all bonus containers (125 stack)
bonus: setup
	@echo "$(GREEN)Starting all containers...$(RESET)"
	$(COMPOSE_BONUS) up --build -d
	@echo "$(GREEN)Full stack is ready.$(RESET)"

# Create data directories on the host
setup:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/portainer

# Stop containers without deleting data
down:
	@echo "$(YELLOW)Stopping containers...$(RESET)"
	$(COMPOSE_BONUS) down
	@echo "$(YELLOW)Containers stopped.$(RESET)"

# Remove containers, networks, and images
clean: down
	@echo "$(RED)Removing images and volumes...$(RESET)"
	$(COMPOSE_BONUS) down --volumes --rmi all
	@echo "$(RED)Clean complete.$(RESET)"

# Full reset: removes everything including data stored on host
fclean: clean
	@echo "$(RED)Removing data directory...$(RESET)"
	sudo rm -rf $(DATA_DIR)
	docker system prune -af
	@echo "$(RED)Full clean complete.$(RESET)"

re: fclean all

.PHONY: all bonus setup down clean fclean re
