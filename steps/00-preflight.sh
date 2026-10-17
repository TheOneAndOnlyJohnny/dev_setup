# shellcheck shell=bash
# Preflight: abort early on unsupported environments, then make sure the Xcode
# Command Line Tools exist (they provide git/clang, needed by Homebrew and oh-my-zsh).

XCODE_CLT_TIMEOUT_SECONDS="${XCODE_CLT_TIMEOUT_SECONDS:-1800}"
XCODE_CLT_POLL_SECONDS="${XCODE_CLT_POLL_SECONDS:-10}"

assert_supported_platform() {
  local os_name architecture
  os_name="$(uname -s)"
  architecture="$(uname -m)"
  if [[ "$os_name" != "Darwin" ]]; then
    log_error "macOS is required (detected: $os_name)"
    return 1
  fi
  if [[ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" == "1" ]]; then
    log_error "This shell runs under Rosetta. Open a native (arm64) terminal and re-run"
    return 1
  fi
  if [[ "$architecture" != "arm64" ]]; then
    log_error "Apple Silicon (arm64) is required (detected: $architecture)"
    return 1
  fi
  log_success "macOS on Apple Silicon"
}

assert_not_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    log_error "Do not run as root or with sudo: Homebrew refuses root and files would be owned by root"
    return 1
  fi
}

wait_for_xcode_clt() {
  local waited_seconds=0
  until xcode-select -p >/dev/null 2>&1; do
    if ((waited_seconds >= XCODE_CLT_TIMEOUT_SECONDS)); then
      log_error "Timed out waiting for Xcode Command Line Tools. Install them and re-run"
      return 1
    fi
    sleep "$XCODE_CLT_POLL_SECONDS"
    waited_seconds=$((waited_seconds + XCODE_CLT_POLL_SECONDS))
  done
  log_success "Xcode Command Line Tools installed"
}

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log_success "Xcode Command Line Tools present"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run_cmd xcode-select --install
    return 0
  fi
  log_warn "Installing Xcode Command Line Tools: accept the macOS dialog to continue"
  # Exits non-zero when an install is already in progress; the wait below covers both cases.
  xcode-select --install >/dev/null 2>&1 || true
  wait_for_xcode_clt
}

assert_supported_platform
assert_not_root
ensure_xcode_clt
