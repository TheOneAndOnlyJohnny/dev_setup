#!/usr/bin/env bats
# Tests for install.sh orchestration, using fixture steps in a throwaway STEPS_DIR.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export STEPS_DIR="$BATS_TEST_TMPDIR/steps"
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  mkdir -p "$HOME" "$STEPS_DIR"
  : >"$TRACE_FILE"
}

# add_step <file name> <body>
add_step() {
  printf '%s\n' "$2" >"$STEPS_DIR/$1"
}

@test "--help lists options and discovered steps" {
  add_step "10-alpha.sh" 'true'
  run /bin/bash "$REPO_ROOT/install.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--dry-run"* ]]
  [[ "$output" == *"  alpha"* ]]
}

@test "unknown flag exits 1 and prints usage" {
  run /bin/bash "$REPO_ROOT/install.sh" --nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --nope"* ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "succeeds with no steps" {
  run /bin/bash "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Setup complete"* ]]
}

@test "runs steps in numeric order and ignores non-step files" {
  add_step "20-second.sh" 'echo second >>"$TRACE_FILE"'
  add_step "10-first.sh" 'echo first >>"$TRACE_FILE"'
  add_step "notes.sh" 'echo stray >>"$TRACE_FILE"'
  run /bin/bash "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "$(printf 'first\nsecond')" ]
}

@test "--skip skips the named step only" {
  add_step "10-first.sh" 'echo first >>"$TRACE_FILE"'
  add_step "20-second.sh" 'echo second >>"$TRACE_FILE"'
  run /bin/bash "$REPO_ROOT/install.sh" --skip first
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "second" ]
  [[ "$output" == *"Skipping first"* ]]
}

@test "--skip with an unknown step fails before running anything" {
  add_step "10-first.sh" 'echo first >>"$TRACE_FILE"'
  run /bin/bash "$REPO_ROOT/install.sh" --skip frist
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown step for --skip: frist"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "a failing command aborts its step and the remaining steps" {
  add_step "10-broken.sh" 'false
echo after-failure >>"$TRACE_FILE"'
  add_step "20-next.sh" 'echo next >>"$TRACE_FILE"'
  run /bin/bash "$REPO_ROOT/install.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Step 'broken' failed"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "steps see parsed flags and lib helpers" {
  add_step "10-flags.sh" 'echo "full=$FULL dry=$DRY_RUN yes=$ASSUME_YES" >>"$TRACE_FILE"
run_cmd touch "$HOME/should-not-exist"'
  run /bin/bash "$REPO_ROOT/install.sh" --full --dry-run --yes
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "full=1 dry=1 yes=1" ]
  [ ! -e "$HOME/should-not-exist" ]
}

@test "steps receive the caller's stdin (prompts are not swallowed)" {
  add_step "10-prompt.sh" 'read -r answer
echo "got:$answer" >>"$TRACE_FILE"'
  run /bin/bash "$REPO_ROOT/install.sh" <<<"hello"
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "got:hello" ]
}

@test "works when invoked from another directory" {
  add_step "10-first.sh" 'echo first >>"$TRACE_FILE"'
  cd "$BATS_TEST_TMPDIR"
  run /bin/bash "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$TRACE_FILE")" = "first" ]
}
