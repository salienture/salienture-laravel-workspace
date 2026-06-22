# Laravel workspace — development commands
# Run `make help` for all targets

SHELL := /bin/bash
ROOT  := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Read APP_PATH from workspace .env at parse time.
# After `make setup` writes it, a fresh make invocation picks it up.
APP_DIR := $(shell grep -s '^APP_PATH=' '$(ROOT).env' 2>/dev/null | cut -d= -f2-)
ifeq ($(APP_DIR),)
  APP_DIR := $(ROOT)app
endif

DOCKER_DIR  := $(ROOT)docker
COMPOSE     := docker compose --env-file $(ROOT).env -f $(DOCKER_DIR)/compose.yml
FRANKENPHP  := $(COMPOSE) exec frankenphp

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# --- Workspace setup ---

.PHONY: setup reconfigure init env link-app
setup: ## Detect / select Laravel app and write workspace .env
	@bash "$(ROOT)scripts/setup.sh"

reconfigure: ## Re-select the active Laravel app (prompts even if already set)
	@bash "$(ROOT)scripts/setup.sh" --reconfigure

init: ## First-time setup: configure app, build containers, install deps, migrate
	@bash "$(ROOT)scripts/setup.sh"
	@$(MAKE) --no-print-directory _init

.PHONY: _init
_init:
	@APP_DIR=$$(grep -s '^APP_PATH=' '$(ROOT).env' | cut -d= -f2-); \
	test -n "$$APP_DIR" || (echo "ERROR: APP_PATH not set. Run: make setup"; exit 1); \
	test -f "$$APP_DIR/artisan" || (echo "ERROR: App not found at $$APP_DIR. Run: make setup"; exit 1)
	$(COMPOSE) build
	$(COMPOSE) up -d
	$(MAKE) --no-print-directory app-install
	$(MAKE) --no-print-directory migrate
	$(FRANKENPHP) php artisan key:generate --no-interaction
	$(FRANKENPHP) php artisan storage:link --no-interaction
	@echo ""
	@echo "  App        http://localhost:$${APP_HTTP_PORT:-8080}"
	@echo "  Mailpit    http://localhost:$${MAILPIT_UI_PORT:-8025}"
	@echo "  phpMyAdmin http://localhost:$${PMA_PORT:-8081}"
	@echo ""
	@echo "  Run 'make vite' in a second terminal to start the frontend dev server."
	@echo ""

env: ## Copy .env templates and patch app .env for Docker services
	@test -f "$(ROOT).env" || cp "$(ROOT).env.example" "$(ROOT).env"
	@if [ -f "$(APP_DIR)/.env.example" ] && [ ! -f "$(APP_DIR)/.env" ]; then \
		cp "$(APP_DIR)/.env.example" "$(APP_DIR)/.env"; \
	fi
	@bash "$(ROOT)scripts/patch-app-env.sh" "$(APP_DIR)/.env"

link-app: ## Symlink a Laravel repo into workspace as app/ (SOURCE=/path/to/repo)
	@SOURCE="$${SOURCE:?Set SOURCE=/path/to/your-laravel-repo}"; \
	SOURCE="$${SOURCE/#\~/$${HOME}}"; \
	if [[ "$${SOURCE}" != /* ]]; then SOURCE="$(ROOT)$${SOURCE}"; fi; \
	ABS="$$(cd "$$SOURCE" && pwd)"; \
	TARGET="$(ROOT)app"; \
	if [ -L "$$TARGET" ]; then \
		ln -sfn "$$ABS" "$$TARGET"; \
	elif [ -d "$$TARGET" ] && [ -f "$$TARGET/artisan" ]; then \
		echo "$$TARGET already contains a Laravel project"; exit 0; \
	else \
		rm -rf "$$TARGET"; \
		ln -sfn "$$ABS" "$$TARGET"; \
	fi; \
	echo "Linked app -> $$ABS"; \
	echo "APP_PATH=$$ABS" >> "$(ROOT).env"

# --- Docker ---

.PHONY: up down restart build logs ps
up: ## Start all core services
	$(COMPOSE) up -d

down: ## Stop and remove containers
	$(COMPOSE) down

restart: ## Restart FrankenPHP
	$(COMPOSE) restart frankenphp

build: ## Rebuild FrankenPHP image
	$(COMPOSE) build --no-cache

logs: ## Follow container logs
	$(COMPOSE) logs -f

ps: ## Show running services
	$(COMPOSE) ps

.PHONY: workers-up workers-down
workers-up: ## Start queue + scheduler (compose profile: workers)
	$(COMPOSE) --profile workers up -d queue scheduler

workers-down: ## Stop queue + scheduler
	$(COMPOSE) --profile workers stop queue scheduler

# --- Laravel (inside FrankenPHP container) ---

.PHONY: shell artisan composer npm
shell: ## Open shell in FrankenPHP container
	$(FRANKENPHP) bash

artisan: ## Run artisan (ARGS="migrate")
	$(FRANKENPHP) php artisan $(ARGS)

composer: ## Run composer in app (ARGS="install")
	$(FRANKENPHP) composer $(ARGS)

npm: ## Run npm on host (ARGS="run dev")
	cd "$(APP_DIR)" && npm $(ARGS)

.PHONY: app-install migrate fresh seed test pint
app-install: ## composer install + npm install
	$(FRANKENPHP) composer install --no-interaction
	@cd "$(APP_DIR)" && npm install

migrate: ## Run database migrations
	$(FRANKENPHP) php artisan migrate

fresh: ## migrate:fresh --seed
	$(FRANKENPHP) php artisan migrate:fresh --seed

seed: ## Run seeders
	$(FRANKENPHP) php artisan db:seed

test: ## Run Pest / PHPUnit
	$(FRANKENPHP) php artisan test

pint: ## Run Laravel Pint (code style)
	$(FRANKENPHP) ./vendor/bin/pint

.PHONY: key-generate cache-clear optimize
key-generate: ## Generate app key
	$(FRANKENPHP) php artisan key:generate

cache-clear: ## Clear all caches
	$(FRANKENPHP) php artisan optimize:clear

optimize: ## Cache config / routes / views
	$(FRANKENPHP) php artisan optimize

# --- Dev workflow ---

.PHONY: dev vite
dev: up workers-up ## Start stack + workers (run Vite separately)
	@echo "Run in another terminal: make vite"

vite: ## Start Vite dev server on host
	cd "$(APP_DIR)" && npm run dev

# --- Database ---

.PHONY: mysql redis-cli
mysql: ## MariaDB CLI
	$(COMPOSE) exec mariadb mariadb -u$${DB_USERNAME} -p$${DB_PASSWORD} $${DB_DATABASE}

redis-cli: ## Redis CLI
	$(COMPOSE) exec redis redis-cli

# --- Cleanup ---

.PHONY: clean destroy
clean: ## Remove stopped containers and dangling images
	$(COMPOSE) down --remove-orphans
	docker image prune -f

destroy: ## Stop containers and delete all volumes (destructive)
	$(COMPOSE) down -v --remove-orphans
