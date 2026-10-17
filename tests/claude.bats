#!/usr/bin/env bats
# Tests for steps/70-claude.sh. curl is faked; its "installer" drops a fake claude into
# ~/.local/bin. PATH excludes any real claude.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  export BACKUP_DIR="$BATS_TEST_TMPDIR/backup"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$HOME" "$FAKE_BIN"
  : >"$TRACE_FILE"
  cat >"$FAKE_BIN/curl" <<'STUB'
#!/bin/bash
echo "curl $*" >>"$TRACE_FILE"
if [ "${FAKE_CURL_FAIL:-0}" = "1" ]; then exit 22; fi
cat <<'INSTALLER'
echo "installer local-bin-on-path=$([[ ":$PATH:" == *":$HOME/.local/bin:"* ]] && echo yes || echo no)" >>"$TRACE_FILE"
if [ "${FAKE_INSTALLER_BREAKS:-0}" != "1" ]; then
  mkdir -p "$HOME/.local/bin"
  printf '#!/bin/bash\n' >"$HOME/.local/bin/claude"
  chmod +x "$HOME/.local/bin/claude"
fi
INSTALLER
STUB
  chmod +x "$FAKE_BIN/curl"
}

run_claude_step() {
  run env PATH="$FAKE_BIN:/usr/bin:/bin" /bin/bash -c "
    set -euo pipefail
    REPO_ROOT='$REPO_ROOT'
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    source '$REPO_ROOT/steps/70-claude.sh'
  "
}

@test "fresh install downloads the native installer with ~/.local/bin on PATH" {
  run_claude_step
  [ "$status" -eq 0 ]
  grep -qx "curl -fsSL https://claude.ai/install.sh" "$TRACE_FILE"
  grep -qx "installer local-bin-on-path=yes" "$TRACE_FILE"
  [ -x "$HOME/.local/bin/claude" ]
  [[ "$output" == *"Claude Code installed"* ]]
}

@test "an existing install in ~/.local/bin is left untouched" {
  mkdir -p "$HOME/.local/bin"
  printf '#!/bin/bash\n' >"$HOME/.local/bin/claude"
  chmod +x "$HOME/.local/bin/claude"
  run_claude_step
  [ "$status" -eq 0 ]
  [ ! -s "$TRACE_FILE" ]
  [[ "$output" == *"Present: Claude Code"* ]]
}

@test "a claude elsewhere on PATH counts as installed" {
  printf '#!/bin/bash\n' >"$FAKE_BIN/claude"
  chmod +x "$FAKE_BIN/claude"
  run_claude_step
  [ "$status" -eq 0 ]
  [ ! -s "$TRACE_FILE" ]
}

@test "dry-run prints the installer command without downloading" {
  run_claude_step --dry-run
  [ "$status" -eq 0 ]
  [ ! -s "$TRACE_FILE" ]
  [[ "$output" == *'[dry-run] /bin/bash -c $(curl -fsSL https://claude.ai/install.sh)'* ]]
}

@test "a failed download fails the step" {
  export FAKE_CURL_FAIL=1
  run_claude_step
  [ "$status" -ne 0 ]
  [ ! -e "$HOME/.local/bin/claude" ]
}

@test "an installer that leaves no binary fails the step" {
  export FAKE_INSTALLER_BREAKS=1
  run_claude_step
  [ "$status" -eq 1 ]
  [[ "$output" == *"claude is missing"* ]]
}

@test "copies CLAUDE.md and settings.json into ~/.claude" {
  run_claude_step
  [ "$status" -eq 0 ]
  cmp -s "$REPO_ROOT/home/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  cmp -s "$REPO_ROOT/home/.claude/settings.json" "$HOME/.claude/settings.json"
}

@test "an existing settings.json is backed up before being replaced" {
  mkdir -p "$HOME/.claude"
  echo '{"mine": true}' >"$HOME/.claude/settings.json"
  run_claude_step
  [ "$status" -eq 0 ]
  [ "$(cat "$BACKUP_DIR/.claude/settings.json")" = '{"mine": true}' ]
}

@test "dry-run copies no Claude files" {
  run_claude_step --dry-run
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude" ]
}

@test "the dotfiles manifest does not manage Claude files (--skip claude leaves them alone)" {
  ! grep -q '^\.claude/' "$REPO_ROOT/manifest.txt"
}

# create_fake_herdr <status line for claude>: `install claude` adds the hook to settings.json.
create_fake_herdr() {
  cat >"$FAKE_BIN/herdr" <<STUB
#!/bin/bash
case "\$1 \$2" in
  "integration status") echo "pi: not installed"; echo "$1" ;;
  "integration install")
    echo "herdr install \$3" >>"\$TRACE_FILE"
    printf '{"hooks": "herdr-agent-state.sh"}\n' >"\$HOME/.claude/settings.json" ;;
esac
STUB
  chmod +x "$FAKE_BIN/herdr"
}

@test "without Herdr the integration is skipped with a warning" {
  run_claude_step
  [ "$status" -eq 0 ]
  [[ "$output" == *"Herdr not found"* ]]
}

@test "Herdr hook is re-added after settings.json is replaced" {
  create_fake_herdr "claude: current (v10) (x)"
  run_claude_step
  [ "$status" -eq 0 ]
  grep -qx "herdr install claude" "$TRACE_FILE"
}

@test "Herdr hook that is current and referenced is left alone" {
  create_fake_herdr "claude: current (v10) (x)"
  mkdir -p "$HOME/.claude"
  cp "$REPO_ROOT/home/.claude/settings.json" "$HOME/.claude/settings.json"
  run_claude_step --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] herdr integration install claude"* ]]
  printf '{"hooks": "herdr-agent-state.sh"}\n' >"$HOME/.claude/settings.json"
  run_claude_step --dry-run
  [[ "$output" == *"Present: Herdr integration"* ]]
  ! grep -q "herdr install" "$TRACE_FILE"
}

@test "an outdated Herdr hook is reinstalled" {
  create_fake_herdr "claude: outdated (v9) (x)"
  mkdir -p "$HOME/.claude"
  printf '{"hooks": "herdr-agent-state.sh"}\n' >"$HOME/.claude/settings.json"
  run_claude_step --dry-run
  [[ "$output" == *"[dry-run] herdr integration install claude"* ]]
}

# install_settings_with_hooks [extra_key]: repo settings.json plus Herdr's hooks (and an optional extra key).
install_settings_with_hooks() {
  mkdir -p "$HOME/.claude"
  python3 - "$REPO_ROOT/home/.claude/settings.json" "$HOME/.claude/settings.json" "${1:-}" <<'PY'
import json, sys
settings = json.load(open(sys.argv[1]))
settings["hooks"] = {"SessionStart": [{"hooks": [{"command": "bash herdr-agent-state.sh session"}]}]}
if sys.argv[3]:
    settings[sys.argv[3]] = True
json.dump(settings, open(sys.argv[2], "w"), indent=4)
PY
}

@test "re-run: settings.json differing only by Herdr hooks is neither backed up nor replaced" {
  create_fake_herdr "claude: current (v10) (x)"
  install_settings_with_hooks
  cp "$HOME/.claude/settings.json" "$BATS_TEST_TMPDIR/before.json"
  run_claude_step
  [ "$status" -eq 0 ]
  [[ "$output" == *"Unchanged: $HOME/.claude/settings.json"* ]]
  cmp -s "$BATS_TEST_TMPDIR/before.json" "$HOME/.claude/settings.json"
  [ ! -e "$BACKUP_DIR/.claude/settings.json" ]
  ! grep -q "herdr install" "$TRACE_FILE"
}

@test "settings.json with other differences besides hooks is still replaced" {
  create_fake_herdr "claude: current (v10) (x)"
  install_settings_with_hooks someLocalKey
  run_claude_step
  [ "$status" -eq 0 ]
  grep -q someLocalKey "$BACKUP_DIR/.claude/settings.json"
  grep -qx "herdr install claude" "$TRACE_FILE"
}

@test "invalid installed settings.json is replaced" {
  mkdir -p "$HOME/.claude"
  echo "not json" >"$HOME/.claude/settings.json"
  run_claude_step
  [ "$status" -eq 0 ]
  [ "$(cat "$BACKUP_DIR/.claude/settings.json")" = "not json" ]
  cmp -s "$REPO_ROOT/home/.claude/settings.json" "$HOME/.claude/settings.json"
}
