DATA_DIR = /home/ael-mans/data
COMPOSE  = docker compose -f srcs/docker-compose.yaml

GREEN  = \033[0;32m
RED    = \033[0;31m
YELLOW = \033[0;33m
RESET  = \033[0m

all: setup
	@echo "$(GREEN)▶ Building and starting containers...$(RESET)"
	$(COMPOSE) up --build -d
	@echo "$(GREEN)✔ All containers are running!$(RESET)"

setup:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb

down:
	@echo "$(YELLOW)▶ Stopping containers...$(RESET)"
	$(COMPOSE) down
	@echo "$(YELLOW)✔ Containers stopped.$(RESET)"

clean: down
	@echo "$(RED)▶ Removing volumes and images...$(RESET)"
	$(COMPOSE) down --volumes --rmi all
	@echo "$(RED)✔ Cleaned.$(RESET)"

fclean: clean
	@echo "$(RED)▶ Removing host data...$(RESET)"
	sudo rm -rf $(DATA_DIR)
	docker system prune -af
	@echo "$(RED)✔ Full clean done.$(RESET)"

re: fclean all

.PHONY: all setup down clean fclean re