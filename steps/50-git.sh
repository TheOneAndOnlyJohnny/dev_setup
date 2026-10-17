# shellcheck shell=bash
# Writes the git identity (user.name / user.email) to ~/.gitconfig.local, which the versioned
# ~/.gitconfig includes. An existing identity is never overwritten. Suggested values come from the
# previous ~/.gitconfig (backed up by the dotfiles step), so re-installing keeps who you are.

GIT_LOCAL_CONFIG="$HOME/.gitconfig.local"

# read_previous_identity_value <key> → value from the backed-up or current ~/.gitconfig, if any.
read_previous_identity_value() {
  local key="$1"
  local config_file value
  for config_file in "$BACKUP_DIR/.gitconfig" "$HOME/.gitconfig"; do
    [[ -f "$config_file" ]] || continue
    value="$(git config --file "$config_file" "$key" || true)"
    if [[ -n "$value" ]]; then
      printf '%s\n' "$value"
      return 0
    fi
  done
}

# ask_with_default <prompt> <default> → the answer, or the default when it is empty.
ask_with_default() {
  local prompt="$1"
  local default_value="$2"
  local answer=""
  if [[ -n "$default_value" ]]; then
    prompt+=" [$default_value]"
  fi
  read -r -p "$prompt: " answer || true
  printf '%s\n' "${answer:-$default_value}"
}

has_git_identity() {
  [[ -n "$(git config --file "$GIT_LOCAL_CONFIG" user.name || true)" ]] &&
    [[ -n "$(git config --file "$GIT_LOCAL_CONFIG" user.email || true)" ]]
}

configure_git_identity() {
  local name email
  if has_git_identity; then
    log_info "Present: git identity in $GIT_LOCAL_CONFIG"
    return 0
  fi
  name="$(read_previous_identity_value user.name)"
  email="$(read_previous_identity_value user.email)"
  if is_interactive && [[ "$ASSUME_YES" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
    name="$(ask_with_default "Git name" "$name")"
    email="$(ask_with_default "Git email" "$email")"
  fi
  if [[ -z "$name" || "$email" != ?*@?* ]]; then
    log_warn "No git identity set. Add it later: git config --file ~/.gitconfig.local user.name \"Your Name\" (and user.email)"
    return 0
  fi
  run_cmd git config --file "$GIT_LOCAL_CONFIG" user.name "$name"
  run_cmd git config --file "$GIT_LOCAL_CONFIG" user.email "$email"
  log_success "Git identity in $GIT_LOCAL_CONFIG: $name <$email>"
}

configure_git_identity
