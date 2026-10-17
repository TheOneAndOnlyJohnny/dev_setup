#!/usr/bin/env bats
# Tests for steps/50-git.sh against a temporary $HOME, with the real git.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export BACKUP_DIR="$BATS_TEST_TMPDIR/backup"
  export XDG_CONFIG_HOME="$HOME/.config"
  unset GIT_CONFIG_GLOBAL GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  LOCAL_CONFIG="$HOME/.gitconfig.local"
  mkdir -p "$HOME"
}

# run_git_step <interactive 0|1> [flags...]; stdin is passed through to the prompts.
run_git_step() {
  local interactive="$1"
  shift
  local override="is_interactive() { false; }"
  if [[ "$interactive" -eq 1 ]]; then
    override="is_interactive() { true; }"
  fi
  run /bin/bash -c "
    set -euo pipefail
    REPO_ROOT='$REPO_ROOT'
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    $override
    source '$REPO_ROOT/steps/50-git.sh'
  "
}

local_value() {
  git config --file "$LOCAL_CONFIG" "$1"
}

write_old_gitconfig() {
  mkdir -p "$(dirname "$1")"
  printf '[user]\n\tname = Old Name\n\temail = old@example.com\n' >"$1"
}

@test "an existing identity is left untouched" {
  printf '[user]\n\tname = Ana\n\temail = ana@example.com\n' >"$LOCAL_CONFIG"
  run_git_step 1 <<<$'Other\nother@example.com'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Present: git identity"* ]]
  [ "$(local_value user.name)" = "Ana" ]
}

@test "non-interactive: reuses the identity from the backed-up ~/.gitconfig" {
  write_old_gitconfig "$BACKUP_DIR/.gitconfig"
  cp "$REPO_ROOT/home/.gitconfig" "$HOME/.gitconfig"
  run_git_step 0
  [ "$status" -eq 0 ]
  [ "$(local_value user.name)" = "Old Name" ]
  [ "$(local_value user.email)" = "old@example.com" ]
}

@test "non-interactive: reuses the identity from the current ~/.gitconfig" {
  write_old_gitconfig "$HOME/.gitconfig"
  run_git_step 0
  [ "$status" -eq 0 ]
  [ "$(local_value user.email)" = "old@example.com" ]
}

@test "non-interactive without a previous identity: warns and writes nothing" {
  run_git_step 0
  [ "$status" -eq 0 ]
  [[ "$output" == *"No git identity set"* ]]
  [ ! -e "$LOCAL_CONFIG" ]
}

@test "interactive: asks for name and email" {
  run_git_step 1 <<<$'Ana Pérez\nana@example.com'
  [ "$status" -eq 0 ]
  [ "$(local_value user.name)" = "Ana Pérez" ]
  [ "$(local_value user.email)" = "ana@example.com" ]
}

@test "interactive: Enter accepts the previous identity" {
  write_old_gitconfig "$BACKUP_DIR/.gitconfig"
  run_git_step 1 <<<$'\n'
  [ "$status" -eq 0 ]
  [ "$(local_value user.name)" = "Old Name" ]
  [ "$(local_value user.email)" = "old@example.com" ]
}

@test "interactive: an invalid email writes nothing" {
  run_git_step 1 <<<$'Ana\nnot-an-email'
  [ "$status" -eq 0 ]
  [[ "$output" == *"No git identity set"* ]]
  [ ! -e "$LOCAL_CONFIG" ]
}

@test "--yes never prompts and uses the previous identity" {
  write_old_gitconfig "$HOME/.gitconfig"
  run_git_step 1 --yes <<<$'Typed\ntyped@example.com'
  [ "$status" -eq 0 ]
  [ "$(local_value user.name)" = "Old Name" ]
}

@test "dry-run prints the writes without prompting or writing" {
  write_old_gitconfig "$HOME/.gitconfig"
  run_git_step 1 --dry-run <<<$'Typed\ntyped@example.com'
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] git config --file $LOCAL_CONFIG user.name Old Name"* ]]
  [ ! -e "$LOCAL_CONFIG" ]
}

@test "repo .gitconfig has no identity or LFS filter and resolves it through the include" {
  # grep exits 1 on no match (2 on error). A bare `! grep` here would never fail the test:
  # bats' errexit ignores negated commands that are not the last line.
  run grep -qE '^\[user\]|filter "lfs"' "$REPO_ROOT/home/.gitconfig"
  [ "$status" -eq 1 ]
  cp "$REPO_ROOT/home/.gitconfig" "$HOME/.gitconfig"
  run_git_step 1 <<<$'Ana\nana@example.com'
  [ "$(git config --global --includes user.email)" = "ana@example.com" ]
  [ "$(git config --global core.autocrlf)" = "input" ]
}
