#!/usr/bin/env bats
# Tests for the zsh functions in home/.dotfiles/setup_functions.sh (run under zsh).

setup() {
  if ! command -v zsh >/dev/null; then
    skip "zsh not installed"
  fi
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FUNCTIONS_FILE="$REPO_ROOT/home/.dotfiles/setup_functions.sh"
  export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
  export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
  export GIT_CONFIG_GLOBAL=/dev/null
}

# create_repo_with_origin <dir> → <dir>/work tracks <dir>/origin.git on main
create_repo_with_origin() {
  local base_dir="$1"
  git init -q --bare -b main "$base_dir/origin.git"
  git init -q -b main "$base_dir/work"
  git -C "$base_dir/work" commit -q --allow-empty -m init
  git -C "$base_dir/work" remote add origin "$base_dir/origin.git"
  git -C "$base_dir/work" push -q -u origin main
}

# --- gmain --------------------------------------------------------------------

@test "gmain: outside a repo returns 1 without killing the shell" {
  cd "$BATS_TEST_TMPDIR"
  run zsh -c "source '$FUNCTIONS_FILE'; gmain; echo \"alive:\$?\""
  [[ "$output" == *"not a Git repository"* ]]
  [[ "$output" == *"alive:1"* ]]
}

@test "gmain: switches to main, restores stashed changes and leaks no globals" {
  create_repo_with_origin "$BATS_TEST_TMPDIR"
  cd "$BATS_TEST_TMPDIR/work"
  echo "clean" >tracked.txt
  git add tracked.txt
  git commit -q -m "add tracked"
  git push -q
  git checkout -q -b feature
  echo "dirty" >tracked.txt
  run zsh -c "source '$FUNCTIONS_FILE'; gmain >/dev/null 2>&1; echo \"status:\$? globals:[\${target_branch:-}\${changes_stashed:-}\${TARGET_BRANCH:-}\${CHANGES_STASHED:-}]\""
  [ "$output" = "status:0 globals:[]" ]
  [ "$(git branch --show-current)" = "main" ]
  [ "$(cat tracked.txt)" = "dirty" ]
}

# --- cleanup ------------------------------------------------------------------
# Every destructive or privileged command is stubbed and only recorded.

create_cleanup_stubs() {
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  mkdir -p "$FAKE_BIN"
  : >"$TRACE_FILE"
  local stub_name
  for stub_name in rm sudo dscacheutil killall atsutil purge; do
    printf '#!/bin/bash\necho "%s $*" >>"$TRACE_FILE"\n' "$stub_name" >"$FAKE_BIN/$stub_name"
  done
  printf '#!/bin/bash\nif [ "$1" = "--cache" ]; then echo "%s/brew-cache"; else echo "brew $*" >>"$TRACE_FILE"; fi\n' "$BATS_TEST_TMPDIR" >"$FAKE_BIN/brew"
  chmod +x "$FAKE_BIN"/*
}

run_cleanup() {
  run env HOME="$BATS_TEST_TMPDIR/home" PATH="$FAKE_BIN:/usr/bin:/bin" \
    zsh -c "source '$FUNCTIONS_FILE'; cleanup; echo \"alive:\$?\""
}

@test "cleanup: cancels without deleting anything when the prompt gets EOF" {
  create_cleanup_stubs
  mkdir -p "$BATS_TEST_TMPDIR/home"
  run_cleanup </dev/null
  [[ "$output" == *"alive:1"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "cleanup: waits for Enter, then cleans DerivedData and quotes the brew cache" {
  create_cleanup_stubs
  derived_data="$BATS_TEST_TMPDIR/home/Library/Developer/Xcode/DerivedData"
  mkdir -p "$derived_data/SomeProject"
  run_cleanup <<<""
  [[ "$output" == *"alive:0"* ]]
  grep -qF "rm -rf $derived_data/SomeProject" "$TRACE_FILE"
  grep -qxF "rm -rf $BATS_TEST_TMPDIR/brew-cache" "$TRACE_FILE"
}

@test "cleanup: survives empty folders (no zsh 'no matches found' abort)" {
  create_cleanup_stubs
  mkdir -p "$BATS_TEST_TMPDIR/home/Library/Caches" "$BATS_TEST_TMPDIR/home/Library/Logs"
  run_cleanup <<<""
  [[ "$output" != *"no matches found"* ]]
  [[ "$output" == *"alive:0"* ]]
  grep -q "^purge" "$TRACE_FILE" || grep -q "sudo purge" "$TRACE_FILE"
}

@test "cleanup: never touches sealed system caches or /private/var/log" {
  create_cleanup_stubs
  mkdir -p "$BATS_TEST_TMPDIR/home"
  run_cleanup <<<""
  ! grep -q "/System/Library/Caches" "$TRACE_FILE"
  ! grep -q "/private/var/log" "$TRACE_FILE"
}

# --- genpass ------------------------------------------------------------------

@test "genpass strong: 20 chars drawn only from the intended set" {
  run zsh -c "source '$FUNCTIONS_FILE'; for i in {1..200}; do genpass strong; done"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 200 ]
  local password
  for password in "${lines[@]}"; do
    [ "${#password}" -eq 20 ]
    # Chars the old `)-_` range leaked in: / : ; \ and digits-adjacent punctuation outside the set
    [[ "$password" != *[/:\;\\\'\"\`~\|]* ]] || { echo "unexpected char in: $password"; false; }
  done
}

@test "genpass: uuid is lowercase and default is 20 chars" {
  run zsh -c "source '$FUNCTIONS_FILE'; genpass uuid; genpass"
  [[ "${lines[0]}" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]
  [ "${#lines[1]}" -eq 20 ]
}
