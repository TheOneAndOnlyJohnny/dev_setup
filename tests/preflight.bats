#!/usr/bin/env bats
# Tests for steps/00-preflight.sh. System commands are stubbed via a fake bin dir on PATH,
# driven by FAKE_* env vars.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  export CLT_MARKER="$BATS_TEST_TMPDIR/clt-installed"
  export XCODE_CLT_POLL_SECONDS=1
  export XCODE_CLT_TIMEOUT_SECONDS=3
  mkdir -p "$HOME"
  : >"$TRACE_FILE"
  touch "$CLT_MARKER"
  create_stubs
}

create_stubs() {
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$FAKE_BIN"
  cat >"$FAKE_BIN/uname" <<'EOF'
#!/bin/bash
case "$1" in
  -s) echo "${FAKE_OS:-Darwin}" ;;
  -m) echo "${FAKE_ARCH:-arm64}" ;;
esac
EOF
  cat >"$FAKE_BIN/sysctl" <<'EOF'
#!/bin/bash
echo "${FAKE_TRANSLATED:-0}"
EOF
  cat >"$FAKE_BIN/id" <<'EOF'
#!/bin/bash
echo "${FAKE_UID:-501}"
EOF
  cat >"$FAKE_BIN/xcode-select" <<'EOF'
#!/bin/bash
case "$1" in
  -p) [ -f "$CLT_MARKER" ] ;;
  --install) echo "install" >>"$TRACE_FILE" ;;
esac
EOF
  # Simulates the user accepting the install dialog after the first poll.
  cat >"$FAKE_BIN/sleep" <<'EOF'
#!/bin/bash
echo "sleep" >>"$TRACE_FILE"
if [ "${FAKE_CLT_READY_AFTER_SLEEP:-0}" = "1" ]; then touch "$CLT_MARKER"; fi
EOF
  chmod +x "$FAKE_BIN"/*
}

run_preflight() {
  run env PATH="$FAKE_BIN:$PATH" /bin/bash -c "
    set -euo pipefail
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    source '$REPO_ROOT/steps/00-preflight.sh'
  "
}

@test "passes on native Apple Silicon, non-root, with CLT present" {
  run_preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"macOS on Apple Silicon"* ]]
  [[ "$output" == *"Xcode Command Line Tools present"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "fails on a non-macOS system" {
  export FAKE_OS=Linux
  run_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"macOS is required (detected: Linux)"* ]]
}

@test "fails on an Intel Mac" {
  export FAKE_ARCH=x86_64
  run_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"Apple Silicon (arm64) is required (detected: x86_64)"* ]]
}

@test "fails under Rosetta with a specific hint" {
  export FAKE_ARCH=x86_64 FAKE_TRANSLATED=1
  run_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"Rosetta"* ]]
}

@test "fails when run as root" {
  export FAKE_UID=0
  run_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"Do not run as root"* ]]
}

@test "installs missing CLT and waits until they are ready" {
  rm "$CLT_MARKER"
  export FAKE_CLT_READY_AFTER_SLEEP=1
  run_preflight
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "$(printf 'install\nsleep')" ]
  [[ "$output" == *"Xcode Command Line Tools installed"* ]]
}

@test "times out when CLT never finish installing" {
  rm "$CLT_MARKER"
  run_preflight
  [ "$status" -eq 1 ]
  [[ "$output" == *"Timed out waiting for Xcode Command Line Tools"* ]]
  [ "$(grep -c sleep "$TRACE_FILE")" -eq 3 ]
}

@test "dry-run reports the CLT install without triggering it" {
  rm "$CLT_MARKER"
  run_preflight --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] xcode-select --install"* ]]
  [ ! -s "$TRACE_FILE" ]
}
