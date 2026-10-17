# shellcheck shell=bash
# Installs Claude Code with Anthropic's native installer (into ~/.local/bin; it self-updates).
# An existing install is left untouched. Then copies the files in manifest.claude.txt
# (~/.claude/CLAUDE.md and the sanitized settings.json) with backup and, when Herdr is
# installed, re-adds its Claude Code hook (the repo's settings.json ships without hooks).

CLAUDE_INSTALL_URL="https://claude.ai/install.sh"
CLAUDE_BIN_DIR="$HOME/.local/bin"
CLAUDE_MANIFEST="${CLAUDE_MANIFEST:-$REPO_ROOT/manifest.claude.txt}"
CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"

install_claude_code() {
  local installer_script
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run_cmd /bin/bash -c "\$(curl -fsSL $CLAUDE_INSTALL_URL)"
    return 0
  fi
  log_info "Installing Claude Code (native installer)"
  installer_script="$(curl -fsSL "$CLAUDE_INSTALL_URL")"
  # On PATH beforehand so the installer sees it and does not append it to ~/.zshrc
  # (starter.sh already exports it).
  PATH="$CLAUDE_BIN_DIR:$PATH" /bin/bash -c "$installer_script"
  if [[ ! -x "$CLAUDE_BIN_DIR/claude" ]]; then
    log_error "Claude Code installer finished but $CLAUDE_BIN_DIR/claude is missing"
    return 1
  fi
  log_success "Claude Code installed at $CLAUDE_BIN_DIR/claude"
}

ensure_claude_code() {
  if [[ -x "$CLAUDE_BIN_DIR/claude" ]] || command_exists claude; then
    log_info "Present: Claude Code"
    return 0
  fi
  install_claude_code
}

# settings_match_ignoring_hooks <source> <target>: true when <target> is the installed
# settings.json and only differs from the repo copy by `hooks` (added by Herdr), so re-runs
# neither back it up nor replace it. Without python3 or valid JSON it is simply copied.
settings_match_ignoring_hooks() {
  [[ "$2" == "$CLAUDE_SETTINGS_FILE" && -f "$2" ]] || return 1
  python3 - "$1" "$2" 2>/dev/null <<'PY'
import json, sys
try:
    repo_settings, installed_settings = (json.load(open(path)) for path in sys.argv[1:3])
except (OSError, ValueError):
    sys.exit(1)
installed_settings.pop("hooks", None)
sys.exit(0 if repo_settings == installed_settings else 1)
PY
}

# True when Herdr reports its hook script current and settings.json references it.
herdr_hook_active() {
  local status_output
  status_output="$(herdr integration status 2>/dev/null || true)"
  grep -q '^claude: current' <<<"$status_output" &&
    grep -q 'herdr-agent-state' "$CLAUDE_SETTINGS_FILE" 2>/dev/null
}

ensure_herdr_integration() {
  if ! command_exists herdr; then
    log_warn "Herdr not found: skipping its Claude Code integration"
    return 0
  fi
  if herdr_hook_active; then
    log_info "Present: Herdr integration for Claude Code"
    return 0
  fi
  run_cmd herdr integration install claude
  log_success "Herdr integration for Claude Code installed"
}

ensure_claude_code
copy_manifest_files "$CLAUDE_MANIFEST" "$REPO_ROOT/home" settings_match_ignoring_hooks
ensure_herdr_integration
