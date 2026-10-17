# shellcheck shell=bash
# Installs the VS Code extensions listed in vscode/extensions.txt that are missing.
# Installed extensions are never updated (VS Code auto-updates them). settings.json is copied
# by the dotfiles step via manifest.txt.

VSCODE_EXTENSIONS_FILE="${VSCODE_EXTENSIONS_FILE:-$REPO_ROOT/vscode/extensions.txt}"
VSCODE_APP_CLI="${VSCODE_APP_CLI:-/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code}"

# Prints the `code` CLI path: PATH first (Homebrew cask), then the app bundle.
find_vscode_cli() {
  if command_exists code; then
    command -v code
  elif [[ -x "$VSCODE_APP_CLI" ]]; then
    printf '%s\n' "$VSCODE_APP_CLI"
  else
    return 1
  fi
}

# Prints extension IDs (lowercase), skipping blank lines and comments.
read_extension_ids() {
  sed -e 's/#.*//' -e 's/[[:space:]]//g' "$1" | grep -v '^$' | tr '[:upper:]' '[:lower:]' || true
}

install_vscode_extensions() {
  local vscode_cli installed_ids wanted_ids extension_id failed_ids=""
  if [[ ! -f "$VSCODE_EXTENSIONS_FILE" ]]; then
    log_error "Extensions list not found: $VSCODE_EXTENSIONS_FILE"
    return 1
  fi
  if ! vscode_cli="$(find_vscode_cli)"; then
    log_warn "VS Code CLI not found: skipping extensions (install VS Code and re-run)"
    return 0
  fi
  wanted_ids="$(read_extension_ids "$VSCODE_EXTENSIONS_FILE")"
  installed_ids="$("$vscode_cli" --list-extensions | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r extension_id; do
    [[ -n "$extension_id" ]] || continue
    if grep -qxF "$extension_id" <<<"$installed_ids"; then
      log_info "Present: $extension_id"
    elif run_cmd "$vscode_cli" --install-extension "$extension_id" </dev/null; then
      log_success "Installed $extension_id"
    else
      failed_ids+="$extension_id "
    fi
  done <<<"$wanted_ids"
  if [[ -n "$failed_ids" ]]; then
    log_error "Failed to install VS Code extensions: $failed_ids"
    return 1
  fi
}

install_vscode_extensions
