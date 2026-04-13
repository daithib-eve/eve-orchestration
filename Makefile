PLATFORM_DIR := $(HOME)/projects/eve/platform
TRADER_DIR   := $(HOME)/projects/eve/trader

.PHONY: dev-up dev-down dev-logs dev-ps

dev-up:
	@echo "Creating dev postgres volume if not present..."
	docker volume create eve-platform-dev-postgres-data || true
	@echo "Building eve-platform app image..."
	docker compose -f $(PLATFORM_DIR)/docker-compose.yml \
	               -f $(PLATFORM_DIR)/docker-compose.dev.yml \
	               --env-file $(PLATFORM_DIR)/.env.dev \
	               -p eve-platform-dev build app
	@echo "Building eve-trader app image..."
	docker compose -f $(TRADER_DIR)/docker-compose.yml \
	               -f $(TRADER_DIR)/docker-compose.dev.yml \
	               --env-file $(PLATFORM_DIR)/.env.dev \
	               -p eve-trader-dev build app
	@echo "Starting eve-platform stack (postgres, nginx, platform app, trader app)..."
	docker compose -f $(PLATFORM_DIR)/docker-compose.yml \
	               -f $(PLATFORM_DIR)/docker-compose.dev.yml \
	               --env-file $(PLATFORM_DIR)/.env.dev \
	               -p eve-platform-dev up -d
	@echo "Dev environment up. nginx on port 8091."

dev-down:
	docker compose -p eve-platform-dev down

dev-logs:
	docker compose -f $(PLATFORM_DIR)/docker-compose.yml \
	               -f $(PLATFORM_DIR)/docker-compose.dev.yml \
	               -p eve-platform-dev logs -f

dev-ps:
	docker compose -p eve-platform-dev ps