# shellcheck shell=bash
# Shared helpers for install.sh and steps/. Requires lib/log.sh.
# Must stay compatible with macOS stock bash 3.2: no mapfile, no associative arrays,
# and empty arrays must be expanded as ${arr[@]+"${arr[@]}"} to survive `set -u`.

FULL=0
DRY_RUN=0
ASSUME_YES=0
SHOW_HELP=0
SKIP_STEPS=()
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
BREW_PREFIX="${BREW_PREFIX:-/opt/homebrew}"

# shellcheck disable=SC2034  # flags are read by install.sh and steps/
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full) FULL=1 ;;
      --dry-run) DRY_RUN=1 ;;
      -y | --yes) ASSUME_YES=1 ;;
      -h | --help) SHOW_HELP=1 ;;
      --skip)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          log_error "--skip requires a step name"
          return 1
        fi
        SKIP_STEPS+=("$2")
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        return 1
        ;;
    esac
    shift
  done
}

is_skipped() {
  local step_name="$1"
  local skipped_step
  for skipped_step in ${SKIP_STEPS[@]+"${SKIP_STEPS[@]}"}; do
    if [[ "$skipped_step" == "$step_name" ]]; then
      return 0
    fi
  done
  return 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Puts an installed Homebrew on PATH. Needed on fresh machines, where the shell
# config doesn't load it yet, and in every step subshell after 10-homebrew.
load_homebrew_env() {
  if command_exists brew; then
    return 0
  fi
  if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  fi
}

# Executes a command, or only prints it when --dry-run is active.
run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_info "[dry-run] $*"
    return 0
  fi
  "$@"
}

# Returns 0 on yes. --yes auto-accepts; a non-interactive stdin declines.
# True when stdin is a terminal. A function so tests can override it.
is_interactive() {
  [[ -t 0 ]]
}

confirm() {
  local prompt="$1"
  local reply
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    return 0
  fi
  if ! is_interactive; then
    return 1
  fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# Prints manifest entries (paths relative to $HOME), one per line, trimmed.
# Skips blank lines and full-line comments; rejects absolute paths and `..`.
read_manifest() {
  local manifest_file="$1"
  local line
  if [[ ! -f "$manifest_file" ]]; then
    log_error "Manifest not found: $manifest_file"
    return 1
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi
    if [[ "$line" == /* || "$line" == ".." || "$line" == ../* || "$line" == */../* || "$line" == */.. ]]; then
      log_error "Invalid manifest entry (must be relative to \$HOME, no '..'): $line"
      return 1
    fi
    printf '%s\n' "$line"
  done <"$manifest_file"
}

# Maps a target path to its location inside BACKUP_DIR, preserving structure.
backup_path_for() {
  local target="$1"
  local relative_path="${target#"$HOME"/}"
  if [[ "$relative_path" == "$target" ]]; then
    relative_path="${target#/}"
  fi
  printf '%s/%s' "$BACKUP_DIR" "$relative_path"
}

# Copies source to target. Identical targets are left alone; differing targets
# (including symlinks) are moved to BACKUP_DIR first. Directories are refused.
backup_and_copy() {
  local source="$1"
  local target="$2"
  if [[ ! -f "$source" ]]; then
    log_error "Source not found: $source"
    return 1
  fi
  if [[ -d "$target" && ! -L "$target" ]]; then
    log_error "Expected a file but found a directory: $target"
    return 1
  fi
  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$source" "$target"; then
    log_info "Unchanged: $target"
    return 0
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    local backup_path
    backup_path="$(backup_path_for "$target")"
    run_cmd mkdir -p "$(dirname "$backup_path")"
    run_cmd cp -RP "$target" "$backup_path"
    run_cmd rm -f "$target"
    log_warn "Backed up $target → $backup_path"
  fi
  run_cmd mkdir -p "$(dirname "$target")"
  run_cmd cp -p "$source" "$target"
  log_success "Installed $target"
}

# copy_manifest_files <manifest> <source_dir> [equivalence_check]: backup_and_copy every entry
# from <source_dir> into $HOME. The whole manifest is validated before anything is copied.
# equivalence_check <source> <target>, if given, returning 0 marks the target as unchanged.
copy_manifest_files() {
  local manifest_file="$1"
  local source_dir="$2"
  local equivalence_check="${3:-}"
  local manifest_entries entry
  manifest_entries="$(read_manifest "$manifest_file")" || return 1
  if [[ -z "$manifest_entries" ]]; then
    log_warn "Manifest is empty: nothing to copy ($manifest_file)"
    return 0
  fi
  while IFS= read -r entry; do
    if [[ -n "$equivalence_check" ]] && "$equivalence_check" "$source_dir/$entry" "$HOME/$entry"; then
      log_info "Unchanged: $HOME/$entry"
      continue
    fi
    backup_and_copy "$source_dir/$entry" "$HOME/$entry"
  done <<<"$manifest_entries"
}
