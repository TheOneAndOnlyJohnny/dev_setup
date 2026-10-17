#!/usr/bin/env bats
# Tests for steps/20-packages.sh with a fake brew that records calls and fails on demand.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  export BREW_PREFIX="$BATS_TEST_TMPDIR/no-homebrew"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$HOME" "$FAKE_BIN"
  : >"$TRACE_FILE"
  # FAKE_SATISFIED / FAKE_INSTALL_FAILS: space-separated Brewfile basenames.
  cat >"$FAKE_BIN/brew" <<'EOF'
#!/bin/bash
last_arg="${@: -1}"
brewfile="$(basename "${last_arg#--file=}")"
echo "brew $2 $brewfile NO_AUTO_UPDATE=${HOMEBREW_NO_AUTO_UPDATE:-}" >>"$TRACE_FILE"
case "$2" in
  check) [[ " ${FAKE_SATISFIED:-} " == *" $brewfile "* ]] ;;
  install) [[ " ${FAKE_INSTALL_FAILS:-} " != *" $brewfile "* ]] ;;
esac
EOF
  chmod +x "$FAKE_BIN/brew"
}

run_packages_step() {
  local path_value="$1"
  shift
  run env PATH="$path_value" /bin/bash -c "
    set -euo pipefail
    REPO_ROOT='$REPO_ROOT'
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    source '$REPO_ROOT/steps/20-packages.sh'
  "
}

@test "installs only the core Brewfile by default" {
  run_packages_step "$FAKE_BIN:/usr/bin:/bin"
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "$(printf 'brew check Brewfile NO_AUTO_UPDATE=1\nbrew install Brewfile NO_AUTO_UPDATE=1')" ]
}

@test "never upgrades: install and check both pass --no-upgrade" {
  sed -i.bak 's/echo "brew \$2/echo "brew $* | $2/' "$FAKE_BIN/brew"
  run_packages_step "$FAKE_BIN:/usr/bin:/bin"
  [ "$status" -eq 0 ]
  [ "$(grep -c -- '--no-upgrade' "$TRACE_FILE")" -eq 2 ]
}

@test "skips install when the core Brewfile is already satisfied" {
  export FAKE_SATISFIED="Brewfile"
  run_packages_step "$FAKE_BIN:/usr/bin:/bin"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Brewfile already satisfied"* ]]
  ! grep -q "install" "$TRACE_FILE"
}

@test "--full installs core then Brewfile.full" {
  run_packages_step "$FAKE_BIN:/usr/bin:/bin" --full
  [ "$status" -eq 0 ]
  [ "$(grep install "$TRACE_FILE" | cut -d' ' -f3)" = "$(printf 'Brewfile\nBrewfile.full')" ]
  [[ "$output" == *"Brewfile.full installed"* ]]
}

@test "a core failure aborts the step" {
  export FAKE_INSTALL_FAILS="Brewfile"
  run_packages_step "$FAKE_BIN:/usr/bin:/bin" --full
  [ "$status" -ne 0 ]
  ! grep -q "Brewfile.full" "$TRACE_FILE"
}

@test "a Brewfile.full failure only warns" {
  export FAKE_INSTALL_FAILS="Brewfile.full"
  run_packages_step "$FAKE_BIN:/usr/bin:/bin" --full
  [ "$status" -eq 0 ]
  [[ "$output" == *"Some Brewfile.full entries failed"* ]]
  [[ "$output" == *"signed in to the App Store"* ]]
}

@test "fails clearly when brew is missing" {
  run_packages_step "/usr/bin:/bin"
  [ "$status" -eq 1 ]
  [[ "$output" == *"brew not found"* ]]
}

@test "dry-run without brew prints the install command" {
  run_packages_step "/usr/bin:/bin" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] brew bundle install --no-upgrade --file=$REPO_ROOT/Brewfile"* ]]
}

@test "dry-run with brew checks but does not install" {
  run_packages_step "$FAKE_BIN:/usr/bin:/bin" --dry-run --full
  [ "$status" -eq 0 ]
  [ "$(cut -d' ' -f2 "$TRACE_FILE" | sort -u)" = "check" ]
  [[ "$output" == *"[dry-run] brew bundle install"* ]]
}

@test "the real Brewfiles parse with Homebrew" {
  if ! command -v brew >/dev/null; then
    skip "Homebrew not installed"
  fi
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --all --file="$REPO_ROOT/Brewfile" >/dev/null
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --all --file="$REPO_ROOT/Brewfile.full" >/dev/null
}
