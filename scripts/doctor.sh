#!/usr/bin/env bash
# Copyright (c) Salienture Private Limited. (https://salienture.com)
#
# Licensed under The MIT License
# For full copyright and license information, please see the LICENSE.txt
# Redistributions of files must retain the above copyright notice.
#
# @copyright Copyright (c) Salienture Private Limited. (https://salienture.com)
# @link      https://salienture.com Salienture
# @since     1.0.0
# @license   https://opensource.org/licenses/mit-license.php MIT License
# @author    Sandeep Kadyan (sandeepk@salienture.com)

# Preflight checks for the workspace Docker stack — surfaces the common
# causes of a cryptic `docker compose` failure (Docker not running, a busy
# port, a missing/misconfigured app) before `make init`/`up`/`dev` gets there.
#
# Usage: bash scripts/doctor.sh

set -uo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${WORKSPACE_ROOT}/.env"
COMPOSE=(docker compose --env-file "$ENV_FILE" -f "${WORKSPACE_ROOT}/docker/compose.yml")

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

fail=0
warn=0

pass()  { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
bad()   { printf '  %s✗%s %s\n' "$RED" "$RESET" "$1"; fail=1; }
warnc() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; warn=1; }

echo ""
echo "${BOLD}Workspace doctor${RESET}"
echo ""

# --- Docker ---

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    pass "Docker is running"
  else
    bad "Docker is installed but not running — start Docker Desktop"
  fi
else
  bad "Docker is not installed"
fi

if docker compose version >/dev/null 2>&1; then
  pass "docker compose is available"
else
  bad "docker compose plugin not found"
fi

# --- .env ---

if [ -f "$ENV_FILE" ]; then
  pass ".env exists"
else
  bad ".env missing — run: cp .env.example .env"
fi

# --- APP_PATH ---

APP_PATH="$(grep -s '^APP_PATH=' "$ENV_FILE" 2>/dev/null | cut -d= -f2-)"
if [ -z "$APP_PATH" ]; then
  warnc "APP_PATH not set — run: make setup"
elif [ ! -f "$APP_PATH/artisan" ]; then
  bad "APP_PATH ($APP_PATH) has no artisan — run: make setup"
else
  pass "Laravel app found at $APP_PATH"
fi

# --- Ports ---

port_free() {
  if command -v lsof >/dev/null 2>&1; then
    ! lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
  else
    ! (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null
  fi
}

check_port() {
  local name="$1" var="$2" default="$3" service="$4" port
  port="$(grep -s "^${var}=" "$ENV_FILE" 2>/dev/null | cut -d= -f2-)"
  port="${port:-$default}"

  if port_free "$port"; then
    pass "Port $port free ($name)"
    return
  fi

  if "${COMPOSE[@]}" ps --status running --services 2>/dev/null | grep -qx "$service"; then
    pass "Port $port in use by this workspace's $name (already running)"
    return
  fi

  warnc "Port $port in use ($name) — stop whatever's on it or change $var in .env"
}

check_port "App HTTP"     APP_HTTP_PORT     8080 frankenphp
check_port "App HTTPS"    APP_HTTPS_PORT    8443 frankenphp
check_port "MariaDB"      DB_PORT           3306 mariadb
check_port "phpMyAdmin"   PMA_PORT          8081 phpmyadmin
check_port "Mailpit UI"   MAILPIT_UI_PORT   8025 mailpit
check_port "Mailpit SMTP" MAILPIT_SMTP_PORT 1025 mailpit
check_port "Redis"        REDIS_PORT        6379 redis

echo ""
if [ "$fail" -eq 1 ]; then
  echo "${RED}${BOLD}Doctor found blocking issues — fix above before continuing.${RESET}"
  echo ""
  exit 1
elif [ "$warn" -eq 1 ]; then
  echo "${YELLOW}Doctor found warnings — you can likely continue, but check above.${RESET}"
  echo ""
else
  echo "${GREEN}All checks passed.${RESET}"
  echo ""
fi
