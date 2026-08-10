#!/usr/bin/env bash
# Prints the workspace splash banner (two-column box, a la Claude Code's TUI header).
#
# Usage: bash scripts/banner.sh

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${WORKSPACE_ROOT}/.env"
CHANGELOG="${WORKSPACE_ROOT}/CHANGELOG.md"

ORANGE=$'\033[38;5;208m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# --- Gather content ---

VERSION="$(grep -m1 -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' "$CHANGELOG" 2>/dev/null | tr -d '[]' || true)"
VERSION="${VERSION:-dev}"

WHO="$(git -C "$WORKSPACE_ROOT" config --get user.name 2>/dev/null || whoami)"
COMPANY="Salienture"

APP_NAME="$(grep -s '^APP_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2-)"
APP_NAME="${APP_NAME:-not configured}"

# Latest two "- " bullets under the newest *released* version section.
WHATS_NEW=()
while IFS= read -r line; do
  [ -n "$line" ] && WHATS_NEW+=("$line")
done < <(awk '/^## \[/{n++} n==2 && /^- /{print; c++} c==2{exit}' "$CHANGELOG" 2>/dev/null || true)
if [ "${#WHATS_NEW[@]}" -eq 0 ]; then
  WHATS_NEW=("See CHANGELOG.md")
fi

CONTRIBUTORS="$(git -C "$WORKSPACE_ROOT" log --format='%an' 2>/dev/null | sort -u | paste -sd, - | sed 's/,/, /g')"
CONTRIBUTORS="${CONTRIBUTORS:-unknown}"

# --- Layout helpers ---

LEFT_W=34
RIGHT_W=44

pad_center() {
  local text="$1" width="$2" len pad_l pad_r
  len=${#text}
  if [ "$len" -ge "$width" ]; then
    printf '%s' "${text:0:width}"
    return
  fi
  pad_l=$(( (width - len) / 2 ))
  pad_r=$(( width - len - pad_l ))
  printf '%*s%s%*s' "$pad_l" '' "$text" "$pad_r" ''
}

pad_left() {
  local text="$1" width="$2" len
  len=${#text}
  if [ "$len" -ge "$width" ]; then
    printf '%s' "${text:0:$((width-1))}…"
    return
  fi
  printf '%-*s' "$width" "$text"
}

# --- Left column ---

left_lines=()
left_lines+=("$(pad_center "Welcome back, ${WHO}!" "$LEFT_W")")
left_lines+=("")
left_lines+=("__ORANGE__$(pad_center '▄▄▄▄▄' "$LEFT_W")")
left_lines+=("__ORANGE__$(pad_center '█▓▓▓█' "$LEFT_W")")
left_lines+=("__ORANGE__$(pad_center '▀▀▀▀▀' "$LEFT_W")")
left_lines+=("")
left_lines+=("__BOLD__$(pad_center "$COMPANY" "$LEFT_W")")
left_lines+=("__DIM__$(pad_center "$APP_NAME" "$LEFT_W")")
left_lines+=("__DIM__$(pad_center "v${VERSION}" "$LEFT_W")")

# --- Right column ---

right_lines=()
right_lines+=("__HEAD__$(pad_left 'Tips for getting started' "$RIGHT_W")")
right_lines+=("$(pad_left 'Run `make vite` for the frontend dev server' "$RIGHT_W")")
right_lines+=("__RULE__")
right_lines+=("__HEAD__$(pad_left "What's new (v${VERSION})" "$RIGHT_W")")
for item in "${WHATS_NEW[@]}"; do
  item="${item#- }"
  right_lines+=("$(pad_left "$item" "$RIGHT_W")")
done
right_lines+=("")
right_lines+=("__DIM__$(pad_left 'CHANGELOG.md for full history' "$RIGHT_W")")
right_lines+=("__DIM__$(pad_left "Contributors: ${CONTRIBUTORS}" "$RIGHT_W")")

max_lines=${#left_lines[@]}
[ "${#right_lines[@]}" -gt "$max_lines" ] && max_lines=${#right_lines[@]}

# --- Borders ---

title=" Laravel Workspace v${VERSION} "
inner_width=$(( LEFT_W + RIGHT_W + 5 ))   # "│ " + L + " │ " + R + " │" minus corners
top_fill_len=$(( inner_width - ${#title} - 2 ))
[ "$top_fill_len" -lt 0 ] && top_fill_len=0
top_fill="$(printf '%*s' "$top_fill_len" '' | tr ' ' '─')"
bottom_fill="$(printf '%*s' "$inner_width" '' | tr ' ' '─')"

echo ""
printf '%s\n' "${ORANGE}╭─${RESET}${BOLD}${title}${RESET}${ORANGE}─${top_fill}╮${RESET}"
for ((i = 0; i < max_lines; i++)); do
  l="${left_lines[$i]:-$(printf '%*s' "$LEFT_W" '')}"
  r="${right_lines[$i]:-$(printf '%*s' "$RIGHT_W" '')}"

  l_style="$RESET"
  case "$l" in
    __BOLD__*)   l="${l#__BOLD__}";   l_style="$BOLD" ;;
    __DIM__*)    l="${l#__DIM__}";    l_style="$DIM" ;;
    __ORANGE__*) l="${l#__ORANGE__}"; l_style="$ORANGE" ;;
  esac

  if [ "$r" = "__RULE__" ]; then
    r="$(printf '%*s' "$RIGHT_W" '' | tr ' ' '─')"
    r_style="$DIM"
  else
    r_style="$RESET"
    case "$r" in
      __HEAD__*) r="${r#__HEAD__}"; r_style="${BOLD}${ORANGE}" ;;
      __DIM__*)  r="${r#__DIM__}";  r_style="$DIM" ;;
    esac
  fi

  printf '%s│%s %s%s%s %s│%s %s%s%s %s│%s\n' \
    "$ORANGE" "$RESET" "$l_style" "$l" "$RESET" \
    "$ORANGE" "$RESET" "$r_style" "$r" "$RESET" \
    "$ORANGE" "$RESET"
done
printf '%s╰%s╯%s\n' "$ORANGE" "$bottom_fill" "$RESET"
echo ""
