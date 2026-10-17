# shellcheck shell=bash
# Installs Brewfile (core) and, with --full, Brewfile.full.
# Never upgrades already-installed packages: re-running the setup must not surprise-upgrade.
# Core failures abort; full-profile failures (typically Mac App Store sign-in) only warn.

CORE_BREWFILE="$REPO_ROOT/Brewfile"
FULL_BREWFILE="$REPO_ROOT/Brewfile.full"

# install_bundle <brewfile> → 0 when satisfied or installed, brew's exit code otherwise.
install_bundle() {
  local brewfile="$1"
  local profile_name
  profile_name="$(basename "$brewfile")"
  if brew bundle check --no-upgrade --file="$brewfile" >/dev/null 2>&1; then
    log_success "$profile_name already satisfied"
    return 0
  fi
  log_info "Installing $profile_name"
  run_cmd brew bundle install --no-upgrade --file="$brewfile"
}

install_full_profile() {
  if install_bundle "$FULL_BREWFILE"; then
    log_success "Brewfile.full installed"
    return 0
  fi
  log_warn "Some Brewfile.full entries failed. Mac App Store apps need you to be signed in to the App Store."
  log_warn "Fix it and re-run ./install.sh --full (installed packages are skipped)."
}

install_packages() {
  if ! command_exists brew; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      run_cmd brew bundle install --no-upgrade --file="$CORE_BREWFILE"
      return 0
    fi
    log_error "brew not found: the homebrew step must run first"
    return 1
  fi
  export HOMEBREW_NO_AUTO_UPDATE=1
  install_bundle "$CORE_BREWFILE"
  log_success "Brewfile installed"
  if [[ "$FULL" -eq 1 ]]; then
    install_full_profile
  fi
}

install_packages
