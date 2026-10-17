# shellcheck shell=bash
# Installs oh-my-zsh, the powerlevel10k theme and the custom plugins enabled in
# home/.dotfiles/starter.sh. Plain git clones instead of the OMZ installer: ~/.zshrc comes
# from home/ and macOS already defaults to zsh. Existing clones are left untouched
# (update them with `omz update` / `git pull`).

OH_MY_ZSH_REPOSITORY="https://github.com/ohmyzsh/ohmyzsh.git"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_DIR="$OH_MY_ZSH_DIR/custom"

# "<path inside ZSH_CUSTOM>|<repository>"
ZSH_EXTENSIONS=(
  "themes/powerlevel10k|https://github.com/romkatv/powerlevel10k.git"
  "plugins/you-should-use|https://github.com/MichaelAquilina/zsh-you-should-use.git"
  "plugins/zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
  "plugins/zsh-completions|https://github.com/zsh-users/zsh-completions.git"
  "plugins/zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search.git"
  "plugins/zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

# ensure_git_clone <repository> <destination>
ensure_git_clone() {
  local repository_url="$1"
  local destination="$2"
  local display_path="${destination#"$HOME"/}"
  if [[ -d "$destination/.git" ]]; then
    log_info "Present: $display_path"
    return 0
  fi
  if [[ -e "$destination" ]]; then
    log_error "$destination exists but is not a git clone. Move it away and re-run"
    return 1
  fi
  run_cmd git clone --quiet --depth=1 "$repository_url" "$destination"
  log_success "Cloned $display_path"
}

warn_if_login_shell_is_not_zsh() {
  if [[ "${SHELL:-}" != */zsh ]]; then
    log_warn "Your login shell is ${SHELL:-unknown}. Switch with: chsh -s /bin/zsh"
  fi
}

install_zsh_stack() {
  local extension extension_path repository_url
  ensure_git_clone "$OH_MY_ZSH_REPOSITORY" "$OH_MY_ZSH_DIR"
  for extension in "${ZSH_EXTENSIONS[@]}"; do
    extension_path="${extension%%|*}"
    repository_url="${extension#*|}"
    ensure_git_clone "$repository_url" "$ZSH_CUSTOM_DIR/$extension_path"
  done
  warn_if_login_shell_is_not_zsh
}

install_zsh_stack
