#!/usr/bin/env bats
# Tests for steps/10-homebrew.sh. curl and the Homebrew installer are faked; the fake
# installer drops a fake brew into BREW_PREFIX. PATH excludes the real Homebrew.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  export BREW_PREFIX="$BATS_TEST_TMPDIR/homebrew"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  export FAKE_BREW_TEMPLATE="$BATS_TEST_TMPDIR/brew-template"
  mkdir -p "$HOME" "$FAKE_BIN"
  : >"$TRACE_FILE"
  create_stubs
}

create_stubs() {
  cat >"$FAKE_BREW_TEMPLATE" <<'EOF'
#!/bin/bash
if [ "$1" = "shellenv" ]; then
  echo "export PATH=\"$BREW_PREFIX/bin:\$PATH\""
fi
EOF
  cat >"$FAKE_BIN/curl" <<'EOF'
#!/bin/bash
echo "curl $*" >>"$TRACE_FILE"
if [ "${FAKE_CURL_FAIL:-0}" = "1" ]; then exit 22; fi
cat <<'INSTALLER'
echo "installer NONINTERACTIVE=${NONINTERACTIVE:-}" >>"$TRACE_FILE"
if [ "${FAKE_INSTALLER_BREAKS:-0}" != "1" ]; then
  mkdir -p "$BREW_PREFIX/bin"
  cp "$FAKE_BREW_TEMPLATE" "$BREW_PREFIX/bin/brew"
  chmod +x "$BREW_PREFIX/bin/brew"
fi
INSTALLER
EOF
  chmod +x "$FAKE_BIN/curl" "$FAKE_BREW_TEMPLATE"
}

preinstall_brew() {
  mkdir -p "$BREW_PREFIX/bin"
  cp "$FAKE_BREW_TEMPLATE" "$BREW_PREFIX/bin/brew"
}

run_homebrew_step() {
  run env PATH="$FAKE_BIN:/usr/bin:/bin" /bin/bash -c "
    set -euo pipefail
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    source '$REPO_ROOT/steps/10-homebrew.sh'
  "
}

@test "skips install when brew exists at BREW_PREFIX but is not on PATH" {
  preinstall_brew
  run_homebrew_step
  [ "$status" -eq 0 ]
  [[ "$output" == *"Homebrew present at $BREW_PREFIX/bin/brew"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "installs Homebrew interactively when missing" {
  run_homebrew_step
  [ "$status" -eq 0 ]
  [[ "$output" == *"Homebrew installed"* ]]
  grep -q "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "$TRACE_FILE"
  grep -qx "installer NONINTERACTIVE=" "$TRACE_FILE"
}

@test "--yes runs the installer with NONINTERACTIVE=1" {
  run_homebrew_step --yes
  [ "$status" -eq 0 ]
  grep -qx "installer NONINTERACTIVE=1" "$TRACE_FILE"
}

@test "fails when the installer download fails" {
  export FAKE_CURL_FAIL=1
  run_homebrew_step
  [ "$status" -ne 0 ]
  ! grep -q "installer" "$TRACE_FILE"
}

@test "fails when the installer finishes without a brew binary" {
  export FAKE_INSTALLER_BREAKS=1
  run_homebrew_step
  [ "$status" -eq 1 ]
  [[ "$output" == *"bin/brew is missing"* ]]
}

@test "dry-run prints the install command without downloading" {
  run_homebrew_step --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] /bin/bash -c"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "install.sh puts Homebrew on PATH for every step" {
  preinstall_brew
  steps_dir="$BATS_TEST_TMPDIR/steps"
  mkdir -p "$steps_dir"
  echo 'command -v brew >>"$TRACE_FILE"' >"$steps_dir/10-check.sh"
  run env PATH="$FAKE_BIN:/usr/bin:/bin" STEPS_DIR="$steps_dir" /bin/bash "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "$BREW_PREFIX/bin/brew" ]
}
