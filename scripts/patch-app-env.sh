#!/usr/bin/env bash
# Patch a Laravel app's .env with Docker Compose service hostnames and DB credentials.
# Called by scripts/setup.sh and `make env`.
set -euo pipefail

ENV_FILE="${1:?Usage: patch-app-env.sh /path/to/app/.env}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load workspace .env so DB_DATABASE, DB_USERNAME, etc. are available
if [[ -f "${ROOT}/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "${ROOT}/.env"
  set +a
fi

set_or_replace() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >>"$ENV_FILE"
  fi
}

set_or_replace APP_URL      "http://localhost:${APP_HTTP_PORT:-8080}"

set_or_replace DB_CONNECTION mysql
set_or_replace DB_HOST       mariadb
set_or_replace DB_PORT       3306
set_or_replace DB_DATABASE   "${DB_DATABASE}"
set_or_replace DB_USERNAME   "${DB_USERNAME}"
set_or_replace DB_PASSWORD   "${DB_PASSWORD:-secret}"

set_or_replace REDIS_HOST    redis
set_or_replace REDIS_PORT    6379

set_or_replace MAIL_MAILER   smtp
set_or_replace MAIL_HOST     mailpit
set_or_replace MAIL_PORT     1025
set_or_replace MAIL_USERNAME null
set_or_replace MAIL_PASSWORD null

set_or_replace CACHE_STORE   redis
set_or_replace SESSION_DRIVER redis
set_or_replace QUEUE_CONNECTION redis

rm -f "${ENV_FILE}.bak"
echo "Patched ${ENV_FILE} for Docker services."
