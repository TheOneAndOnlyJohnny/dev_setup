#!/usr/bin/env bats
# Tests for steps/60-vscode.sh with a fake `code` CLI that records installs.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  export VSCODE_APP_CLI="$BATS_TEST_TMPDIR/no-app/code"
  export VSCODE_EXTENSIONS_FILE="$BATS_TEST_TMPDIR/extensions.txt"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$HOME" "$FAKE_BIN"
  : >"$TRACE_FILE"
  printf '# comment\n\nCatppuccin.catppuccin-vsc  # theme\nredhat.vscode-yaml\n' >"$VSCODE_EXTENSIONS_FILE"
  # FAKE_INSTALLED: newline-separated IDs; FAKE_INSTALL_FAILS: space-separated IDs.
  cat >"$FAKE_BIN/code" <<'STUB'
#!/bin/bash
case "$1" in
  --list-extensions) printf '%s' "${FAKE_INSTALLED:-}" ;;
  --install-extension)
    echo "install $2" >>"$TRACE_FILE"
    [[ " ${FAKE_INSTALL_FAILS:-} " != *" $2 "* ]] ;;
esac
STUB
  chmod +x "$FAKE_BIN/code"
}

run_vscode_step() {
  run env PATH="$FAKE_BIN:/usr/bin:/bin" /bin/bash -c "
    set -euo pipefail
    REPO_ROOT='$REPO_ROOT'
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    source '$REPO_ROOT/steps/60-vscode.sh'
  "
}

@test "installs every listed extension, ignoring comments and case" {
  run_vscode_step
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "$(printf 'install catppuccin.catppuccin-vsc\ninstall redhat.vscode-yaml')" ]
}

@test "already installed extensions are not reinstalled (no upgrades)" {
  export FAKE_INSTALLED=$'Catppuccin.Catppuccin-vsc\nredhat.vscode-yaml\n'
  run_vscode_step
  [ "$status" -eq 0 ]
  [ ! -s "$TRACE_FILE" ]
  [[ "$output" == *"Present: redhat.vscode-yaml"* ]]
}

@test "one failed install still tries the rest, then fails the step" {
  export FAKE_INSTALL_FAILS="catppuccin.catppuccin-vsc"
  run_vscode_step
  [ "$status" -eq 1 ]
  grep -qx "install redhat.vscode-yaml" "$TRACE_FILE"
  [[ "$output" == *"Failed to install VS Code extensions: catppuccin.catppuccin-vsc"* ]]
}

@test "dry-run prints installs without running them" {
  run_vscode_step --dry-run
  [ "$status" -eq 0 ]
  [ ! -s "$TRACE_FILE" ]
  [[ "$output" == *"[dry-run] $FAKE_BIN/code --install-extension redhat.vscode-yaml"* ]]
}

@test "without VS Code it warns and skips" {
  rm "$FAKE_BIN/code"
  run_vscode_step
  [ "$status" -eq 0 ]
  [[ "$output" == *"VS Code CLI not found"* ]]
}

@test "falls back to the CLI inside the app bundle" {
  mkdir -p "$(dirname "$VSCODE_APP_CLI")"
  mv "$FAKE_BIN/code" "$VSCODE_APP_CLI"
  run_vscode_step
  [ "$status" -eq 0 ]
  grep -qx "install redhat.vscode-yaml" "$TRACE_FILE"
}

@test "repo extensions.txt has valid publisher.name IDs and no duplicates" {
  local ids
  ids="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$REPO_ROOT/vscode/extensions.txt" | grep -v '^$' | tr '[:upper:]' '[:lower:]')"
  [ -n "$ids" ]
  # `run` + status: a bare `! grep` mid-test never fails it (bats' errexit ignores negations).
  run grep -vqE '^[a-z0-9-]+\.[a-z0-9-]+$' <<<"$ids"
  [ "$status" -eq 1 ]
  [ -z "$(sort <<<"$ids" | uniq -d)" ]
}

@test "repo settings.json is valid JSON" {
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$REPO_ROOT/home/Library/Application Support/Code/User/settings.json"
}
