PLATFORM_DIR      := $(HOME)/projects/eve/platform
TRADER_DIR        := $(HOME)/projects/eve/trader
PROD_PLATFORM_DIR := /opt/eve/platform
PROD_TRADER_DIR   := /opt/eve/trader

.PHONY: dev-up dev-down dev-logs dev-ps prod-deploy

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
	@echo "Building eve-ledger app image..."
	docker compose -f $(PLATFORM_DIR)/docker-compose.yml \
	               -f $(PLATFORM_DIR)/docker-compose.dev.yml \
	               --env-file $(PLATFORM_DIR)/.env.dev \
	               -p eve-platform-dev build eve-ledger-app
	@echo "Starting eve-platform stack (postgres, nginx, platform app, trader app, ledger app)..."
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

prod-deploy:
	@echo "==================================================================="
	@echo "  PROD DEPLOY — $(shell date)"
	@echo "==================================================================="
	@echo ""
	@echo "--- [1/6] Pulling latest code ---"
	sudo git -C $(PROD_PLATFORM_DIR) reset --hard origin/main
	sudo git -C $(PROD_TRADER_DIR) reset --hard origin/main
	@echo ""
	@echo "--- [2/6] Backing up database ---"
	sudo docker exec eve-platform-prod-postgres pg_dump -U eve_trader eve_trader \
		| sudo tee /opt/eve/backups/eve_trader_$$(date +%Y%m%d_%H%M%S).sql > /dev/null
	@echo "Backup written to /opt/eve/backups/"
	@echo ""
	@echo "--- [3/6] Applying eve-platform migrations ---"
	@bash -c 'for f in $$(ls $(PROD_PLATFORM_DIR)/eve_platform/db/migrations/*.sql | sort); do echo "  Applying $$f..."; sudo docker exec -i eve-platform-prod-postgres psql -U eve_trader -d eve_trader < "$$f"; done'
	@echo ""
	@echo "--- [4/6] Applying eve-trader migrations ---"
	@bash -c 'for f in $$(ls $(PROD_TRADER_DIR)/eve_trader/db/migrations/*.sql | sort); do echo "  Applying $$f..."; sudo docker exec -i eve-platform-prod-postgres psql -U eve_trader -d eve_trader < "$$f"; done'
	@echo ""
	@echo "--- [5/6] Restarting prod stack (rebuilds stale images) ---"
	docker compose \
	  -f /opt/eve/platform/docker-compose.yml \
	  -f /opt/eve/platform/docker-compose.prod.yml \
	  --env-file /opt/eve/platform/.env.prod \
	  up -d --build
	@echo ""
	@echo "Waiting 15 seconds for stack to stabilise..."
	sleep 15
	@echo "--- Health check ---"
	@if curl -sf http://localhost:8090/health | python3 -m json.tool; then \
		echo ""; \
		echo "SUCCESS: prod deploy complete."; \
	else \
		echo ""; \
		echo "FAILURE: health check failed — check: make -C /opt/eve prod-logs"; \
		exit 1; \
	fi