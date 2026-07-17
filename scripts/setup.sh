#!/usr/bin/env bash
# Detect or interactively select a Laravel application inside app/.
# Writes APP_NAME, APP_PATH, COMPOSE_PROJECT_NAME to workspace .env
#
# Usage:
#   bash scripts/setup.sh              # auto or interactive
#   bash scripts/setup.sh --reconfigure  # force re-selection even if already set

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPS_DIR="${WORKSPACE_ROOT}/app"
ENV_FILE="${WORKSPACE_ROOT}/.env"

# --- Terminal helpers ---
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m' "$*"; }
dim()    { printf '\033[2m%s\033[0m\n' "$*"; }

is_laravel() { [[ -f "$1/artisan" && -f "$1/composer.json" ]]; }

set_or_replace() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "${ENV_FILE}" 2>/dev/null; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "${ENV_FILE}"
  else
    echo "${key}=${value}" >>"${ENV_FILE}"
  fi
  rm -f "${ENV_FILE}.bak"
}

# --- Check if already configured ---
RECONFIGURE=false
[[ "${1:-}" == "--reconfigure" ]] && RECONFIGURE=true

if [[ -f "${ENV_FILE}" ]] && ! $RECONFIGURE; then
  CURRENT_APP_PATH="$(grep -s '^APP_PATH=' "${ENV_FILE}" | cut -d= -f2- || true)"
  if [[ -n "${CURRENT_APP_PATH}" && -f "${CURRENT_APP_PATH}/artisan" ]]; then
    green "Workspace already configured: $(basename "${CURRENT_APP_PATH}")"
    dim  "  Path: ${CURRENT_APP_PATH}"
    if [[ -t 0 ]]; then
      printf "Change application? [y/N]: "
      read -r change_ans
      if [[ ! "${change_ans}" =~ ^[Yy]$ ]]; then
        exit 0
      fi
      echo ""
    else
      dim "  To change: bash scripts/setup.sh --reconfigure"
      exit 0
    fi
  fi
fi

echo ""
bold "Laravel Workspace Setup"
printf '\n'

# --- Ensure .env exists ---
if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${WORKSPACE_ROOT}/.env.example" "${ENV_FILE}"
  green "Created .env from .env.example"
fi

# --- Ensure app/ container exists ---
mkdir -p "${APPS_DIR}"
touch "${APPS_DIR}/.gitkeep"

# --- Scan app/ for Laravel apps ---
declare -a APPS=()
if [[ -d "${APPS_DIR}" ]]; then
  for dir in "${APPS_DIR}"/*/; do
    [[ -d "$dir" ]] || continue
    dir="${dir%/}"
    name="$(basename "$dir")"
    [[ "$name" == .* ]] && continue
    is_laravel "$dir" && APPS+=("$dir")
  done
fi

# --- Resolve which app to use ---
CHOSEN_APP_PATH=""

if [[ ${#APPS[@]} -eq 0 ]]; then
  yellow "No Laravel application found in app/."
  echo ""
  echo "Clone your Laravel app into the app/ directory:"
  dim  "  cd ${WORKSPACE_ROOT}/app"
  dim  "  git clone <your-laravel-repo>"
  echo ""
  printf "Or enter the path to an existing Laravel app: "
  read -r user_path
  user_path="${user_path/#\~/$HOME}"
  if [[ "${user_path}" != /* ]]; then
    user_path="${WORKSPACE_ROOT}/${user_path}"
  fi
  ABS_PATH="$(cd "${user_path}" 2>/dev/null && pwd)" || { red "Path not found: ${user_path}"; exit 1; }
  is_laravel "${ABS_PATH}" || { red "No artisan found at ${ABS_PATH} — not a Laravel app"; exit 1; }
  CHOSEN_APP_PATH="${ABS_PATH}"

elif [[ ${#APPS[@]} -eq 1 ]]; then
  CHOSEN_APP_PATH="${APPS[0]}"
  green "Found Laravel app: $(basename "${CHOSEN_APP_PATH}")"

else
  bold "Multiple Laravel apps found in app/:\n"
  for i in "${!APPS[@]}"; do
    printf "  \033[36m%d)\033[0m %s\n" $((i + 1)) "$(basename "${APPS[$i]}")"
  done
  echo ""
  printf "Choose [1-%d]: " "${#APPS[@]}"
  read -r choice
  idx=$((choice - 1))
  if [[ $idx -lt 0 || $idx -ge ${#APPS[@]} ]]; then
    red "Invalid choice: ${choice}"
    exit 1
  fi
  CHOSEN_APP_PATH="${APPS[$idx]}"
fi

APP_NAME="$(basename "${CHOSEN_APP_PATH}")"
COMPOSE_PROJECT_NAME="$(echo "${APP_NAME}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9_-' '-' | sed 's/-$//')"

# --- Write workspace .env ---
set_or_replace APP_NAME             "${APP_NAME}"
set_or_replace APP_PATH             "${CHOSEN_APP_PATH}"
set_or_replace COMPOSE_PROJECT_NAME "${COMPOSE_PROJECT_NAME}"
set_or_replace DB_DATABASE          "${COMPOSE_PROJECT_NAME}"
set_or_replace DB_USERNAME          "${COMPOSE_PROJECT_NAME}"

# --- Copy and patch the app .env ---
APP_ENV_FILE="${CHOSEN_APP_PATH}/.env"
if [[ -f "${CHOSEN_APP_PATH}/.env.example" && ! -f "${APP_ENV_FILE}" ]]; then
  cp "${CHOSEN_APP_PATH}/.env.example" "${APP_ENV_FILE}"
  green "Created ${APP_NAME}/.env from .env.example"
fi

if [[ -f "${APP_ENV_FILE}" ]]; then
  bash "${WORKSPACE_ROOT}/scripts/patch-app-env.sh" "${APP_ENV_FILE}"
fi

# --- Summary ---
echo ""
bold "Workspace configured"
printf '\n'
printf "  App name : \033[36m%s\033[0m\n" "${APP_NAME}"
printf "  Path     : %s\n" "${CHOSEN_APP_PATH}"
printf "  Project  : %s\n" "${COMPOSE_PROJECT_NAME}"
printf "  Database : %s\n" "${COMPOSE_PROJECT_NAME}"
echo ""
green "Next: make init"
