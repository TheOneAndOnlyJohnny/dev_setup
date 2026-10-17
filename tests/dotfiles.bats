#!/usr/bin/env bats
# Tests for steps/40-dotfiles.sh against a temporary $HOME (real manifest.txt and home/ by default).

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export BACKUP_DIR="$BATS_TEST_TMPDIR/backup"
  mkdir -p "$HOME"
}

run_dotfiles_step() {
  run /bin/bash -c "
    set -euo pipefail
    REPO_ROOT='$REPO_ROOT'
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    source '$REPO_ROOT/steps/40-dotfiles.sh'
  "
}

# Prints every manifest entry whose copy in $HOME differs from home/.
list_mismatches() {
  local entry
  while IFS= read -r entry; do
    cmp -s "$REPO_ROOT/home/$entry" "$HOME/$entry" || echo "$entry"
  done < <(grep -vE '^[[:space:]]*(#|$)' "$REPO_ROOT/manifest.txt")
}

@test "fresh home: copies every manifest entry and creates no backup" {
  run_dotfiles_step
  [ "$status" -eq 0 ]
  [ -z "$(list_mismatches)" ]
  [ ! -e "$BACKUP_DIR" ]
}

@test "second run changes nothing" {
  run_dotfiles_step
  run_dotfiles_step
  [ "$status" -eq 0 ]
  [[ "$output" != *"Installed"* ]]
  [[ "$output" == *"Unchanged: $HOME/.zshrc"* ]]
  [ ! -e "$BACKUP_DIR" ]
}

@test "a different existing file is backed up before being replaced" {
  echo "my old zshrc" >"$HOME/.zshrc"
  run_dotfiles_step
  [ "$status" -eq 0 ]
  [ "$(cat "$BACKUP_DIR/.zshrc")" = "my old zshrc" ]
  cmp -s "$REPO_ROOT/home/.zshrc" "$HOME/.zshrc"
}

@test "files outside the manifest are left alone" {
  mkdir -p "$HOME/.dotfiles"
  echo "personal" >"$HOME/.dotfiles/extra.sh"
  run_dotfiles_step
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.dotfiles/extra.sh")" = "personal" ]
}

@test "dry-run writes nothing to \$HOME or the backup dir" {
  echo "my old zshrc" >"$HOME/.zshrc"
  run_dotfiles_step --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] cp -p $REPO_ROOT/home/.p10k.zsh $HOME/.p10k.zsh"* ]]
  [ "$(cat "$HOME/.zshrc")" = "my old zshrc" ]
  [ "$(ls -A "$HOME")" = ".zshrc" ]
  [ ! -e "$BACKUP_DIR" ]
}

@test "an invalid manifest aborts before copying anything" {
  printf '.zshrc\n/etc/hosts\n' >"$BATS_TEST_TMPDIR/manifest.txt"
  export DOTFILES_MANIFEST="$BATS_TEST_TMPDIR/manifest.txt"
  run_dotfiles_step
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid manifest entry"* ]]
  [ ! -e "$HOME/.zshrc" ]
}

@test "a manifest entry missing from home/ fails the step" {
  printf '.does-not-exist\n' >"$BATS_TEST_TMPDIR/manifest.txt"
  export DOTFILES_MANIFEST="$BATS_TEST_TMPDIR/manifest.txt"
  run_dotfiles_step
  [ "$status" -ne 0 ]
  [[ "$output" == *"Source not found"* ]]
}

@test "an empty manifest only warns" {
  printf '# nothing\n' >"$BATS_TEST_TMPDIR/manifest.txt"
  export DOTFILES_MANIFEST="$BATS_TEST_TMPDIR/manifest.txt"
  run_dotfiles_step
  [ "$status" -eq 0 ]
  [[ "$output" == *"Manifest is empty"* ]]
}
