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

# Run database migrations. If a migration fails because its table already
# exists (SQLSTATE 42S01 — common after a restored dump, a manually created
# table, or a migration that previously ran but crashed before its row was
# recorded), mark that one migration as already applied and keep going,
# instead of aborting the whole batch.
#
# Usage: bash scripts/migrate.sh

set -uo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${WORKSPACE_ROOT}/.env"
ARTISAN=(docker compose --env-file "$ENV_FILE" -f "${WORKSPACE_ROOT}/docker/compose.yml" exec frankenphp php artisan)

YELLOW=$'\033[33m'
RESET=$'\033[0m'

MAX_ALREADY_EXISTS=20

for ((i = 1; i <= MAX_ALREADY_EXISTS; i++)); do
  OUTPUT="$("${ARTISAN[@]}" migrate --force 2>&1)"
  STATUS=$?
  echo "$OUTPUT"

  [ "$STATUS" -eq 0 ] && exit 0

  if ! echo "$OUTPUT" | grep -qi 'already exists'; then
    exit "$STATUS"
  fi

  MIGRATION="$(echo "$OUTPUT" | grep -E 'FAIL[[:space:]]*$' | tail -1 | awk '{print $1}')"
  if [ -z "$MIGRATION" ]; then
    exit "$STATUS"
  fi

  echo ""
  echo "  ${YELLOW}!${RESET} Table for '$MIGRATION' already exists — marking that migration as already applied and continuing."
  echo ""

  "${ARTISAN[@]}" tinker --execute="DB::table('migrations')->insert(['migration' => '${MIGRATION}', 'batch' => (int) (DB::table('migrations')->max('batch') ?? 0) + 1]);" >/dev/null 2>&1
done

echo "  Stopped after ${MAX_ALREADY_EXISTS} already-existing tables — check the schema manually."
exit 1
