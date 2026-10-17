# shellcheck shell=bash
# Installs Homebrew with the official installer when missing.
# Packages are installed later by 20-packages.

HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

install_homebrew() {
  local installer_script
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run_cmd /bin/bash -c "\$(curl -fsSL $HOMEBREW_INSTALL_URL)"
    return 0
  fi
  log_info "Installing Homebrew (it will ask for your password)"
  installer_script="$(curl -fsSL "$HOMEBREW_INSTALL_URL")"
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$installer_script"
  else
    /bin/bash -c "$installer_script"
  fi
  load_homebrew_env
  if ! command_exists brew; then
    log_error "Homebrew installer finished but $BREW_PREFIX/bin/brew is missing"
    return 1
  fi
  log_success "Homebrew installed"
}

ensure_homebrew() {
  load_homebrew_env
  if command_exists brew; then
    log_success "Homebrew present at $(command -v brew)"
    return 0
  fi
  install_homebrew
}

ensure_homebrew
