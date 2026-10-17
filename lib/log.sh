# shellcheck shell=bash
# Logging helpers. Colors only when stdout is a terminal and NO_COLOR is unset.
# Warnings and errors go to stderr.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  _LOG_BOLD=$'\033[1m'
  _LOG_RED=$'\033[31m'
  _LOG_GREEN=$'\033[32m'
  _LOG_YELLOW=$'\033[33m'
  _LOG_BLUE=$'\033[34m'
  _LOG_RESET=$'\033[0m'
else
  _LOG_BOLD='' _LOG_RED='' _LOG_GREEN='' _LOG_YELLOW='' _LOG_BLUE='' _LOG_RESET=''
fi

log_step()    { printf '\n%s▶ %s%s\n' "$_LOG_BOLD" "$*" "$_LOG_RESET"; }
log_info()    { printf '%s==>%s %s\n' "$_LOG_BLUE" "$_LOG_RESET" "$*"; }
log_success() { printf '%s✔%s %s\n' "$_LOG_GREEN" "$_LOG_RESET" "$*"; }
log_warn()    { printf '%s⚠%s %s\n' "$_LOG_YELLOW" "$_LOG_RESET" "$*" >&2; }
log_error()   { printf '%s✖%s %s\n' "$_LOG_RED" "$_LOG_RESET" "$*" >&2; }
