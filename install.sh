#!/usr/bin/env bash
# Entrypoint: ./install.sh [--full] [--dry-run] [--yes] [--skip <step>]...
# Runs every steps/NN-name.sh in numeric order. Each step runs in a subshell with
# `set -e`, sharing lib/ helpers and parsed flags; the first failure aborts the install.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${STEPS_DIR:-$REPO_ROOT/steps}"
STEP_FILES=()

# shellcheck source=lib/log.sh
source "$REPO_ROOT/lib/log.sh"
# shellcheck source=lib/utils.sh
source "$REPO_ROOT/lib/utils.sh"

# Collected into an array (not streamed through `while read`) so steps keep the
# terminal as stdin for prompts.
collect_step_files() {
  local step_file
  for step_file in "$STEPS_DIR"/[0-9][0-9]-*.sh; do
    if [[ -f "$step_file" ]]; then
      STEP_FILES+=("$step_file")
    fi
  done
}

# "steps/30-zsh.sh" → "zsh"
step_name_of() {
  local base_name
  base_name="$(basename "$1" .sh)"
  printf '%s' "${base_name#[0-9][0-9]-}"
}

print_usage() {
  local step_file
  cat <<EOF
Usage: ./install.sh [options]

Options:
  --full           Also install personal apps from Brewfile.full
  --dry-run        Print every action without changing anything
  -y, --yes        Answer yes to every prompt (non-interactive)
  --skip <step>    Skip a step (repeatable)
  -h, --help       Show this help

Steps:
EOF
  for step_file in ${STEP_FILES[@]+"${STEP_FILES[@]}"}; do
    printf '  %s\n' "$(step_name_of "$step_file")"
  done
}

# Fails on --skip values that match no step, so typos don't silently run everything.
validate_skips() {
  local skipped_step step_file found
  for skipped_step in ${SKIP_STEPS[@]+"${SKIP_STEPS[@]}"}; do
    found=0
    for step_file in ${STEP_FILES[@]+"${STEP_FILES[@]}"}; do
      if [[ "$(step_name_of "$step_file")" == "$skipped_step" ]]; then
        found=1
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      log_error "Unknown step for --skip: $skipped_step (see --help)"
      return 1
    fi
  done
}

run_step() {
  local step_file="$1"
  local step_name exit_code
  step_name="$(step_name_of "$step_file")"
  if is_skipped "$step_name"; then
    log_warn "Skipping $step_name (--skip)"
    return 0
  fi
  log_step "$step_name"
  # errexit is ignored inside `( … ) || …`, so the status is captured with set +e instead.
  set +e
  (
    set -euo pipefail
    load_homebrew_env
    # shellcheck source=/dev/null
    source "$step_file"
  )
  exit_code=$?
  set -e
  if [[ "$exit_code" -ne 0 ]]; then
    log_error "Step '$step_name' failed (exit $exit_code). Fix the issue and re-run: completed steps are idempotent."
    return "$exit_code"
  fi
}

main() {
  local step_file
  collect_step_files
  if ! parse_flags "$@"; then
    print_usage >&2
    exit 1
  fi
  if [[ "$SHOW_HELP" -eq 1 ]]; then
    print_usage
    exit 0
  fi
  validate_skips
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_warn "Dry-run: no changes will be made"
  fi
  for step_file in ${STEP_FILES[@]+"${STEP_FILES[@]}"}; do
    run_step "$step_file"
  done
  if [[ -d "$BACKUP_DIR" ]]; then
    log_info "Previous files backed up to $BACKUP_DIR"
  fi
  log_success "Setup complete"
}

main "$@"
