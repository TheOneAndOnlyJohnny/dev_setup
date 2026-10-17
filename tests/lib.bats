#!/usr/bin/env bats
# Tests for lib/log.sh and lib/utils.sh. Every test runs against a throwaway $HOME.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  mkdir -p "$HOME"
  # shellcheck source=../lib/log.sh
  source "$REPO_ROOT/lib/log.sh"
  # shellcheck source=../lib/utils.sh
  source "$REPO_ROOT/lib/utils.sh"
  BACKUP_DIR="$BATS_TEST_TMPDIR/backup"
  SOURCE_FILE="$BATS_TEST_TMPDIR/source.txt"
  printf 'new\n' >"$SOURCE_FILE"
}

# --- log.sh -------------------------------------------------------------------

@test "log_error and log_warn write to stderr only" {
  stdout_only="$(bash -c "source '$REPO_ROOT/lib/log.sh'; log_error boom; log_warn careful" 2>/dev/null)"
  [ -z "$stdout_only" ]
}

@test "log output has no ANSI codes when NO_COLOR is set" {
  run log_info "hello"
  [ "$output" = "==> hello" ]
}

# --- parse_flags --------------------------------------------------------------

@test "parse_flags: defaults when no flags are given" {
  parse_flags
  [ "$FULL" -eq 0 ]
  [ "$DRY_RUN" -eq 0 ]
  [ "$ASSUME_YES" -eq 0 ]
  [ "$SHOW_HELP" -eq 0 ]
  [ "${#SKIP_STEPS[@]}" -eq 0 ]
}

@test "parse_flags: sets every flag and collects repeated --skip" {
  parse_flags --full --dry-run --yes --skip zsh --skip vscode
  [ "$FULL" -eq 1 ]
  [ "$DRY_RUN" -eq 1 ]
  [ "$ASSUME_YES" -eq 1 ]
  [ "${#SKIP_STEPS[@]}" -eq 2 ]
  [ "${SKIP_STEPS[0]}" = "zsh" ]
  [ "${SKIP_STEPS[1]}" = "vscode" ]
}

@test "parse_flags: short aliases -y and -h" {
  parse_flags -y -h
  [ "$ASSUME_YES" -eq 1 ]
  [ "$SHOW_HELP" -eq 1 ]
}

@test "parse_flags: --skip without a value fails" {
  run parse_flags --skip
  [ "$status" -eq 1 ]
  [[ "$output" == *"--skip requires a step name"* ]]
}

@test "parse_flags: --skip followed by another flag fails" {
  run parse_flags --skip --full
  [ "$status" -eq 1 ]
}

@test "parse_flags: unknown option fails" {
  run parse_flags --nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --nope"* ]]
}

# --- is_skipped ---------------------------------------------------------------

@test "is_skipped: matches only listed steps" {
  SKIP_STEPS=(zsh claude)
  is_skipped zsh
  is_skipped claude
  run is_skipped vscode
  [ "$status" -eq 1 ]
}

@test "is_skipped: empty list is safe under set -u on stock bash" {
  run /bin/bash -c "set -euo pipefail; source '$REPO_ROOT/lib/log.sh'; source '$REPO_ROOT/lib/utils.sh'; is_skipped zsh"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

# --- run_cmd ------------------------------------------------------------------

@test "run_cmd: executes the command normally" {
  run_cmd touch "$BATS_TEST_TMPDIR/created"
  [ -f "$BATS_TEST_TMPDIR/created" ]
}

@test "run_cmd: only prints in dry-run" {
  DRY_RUN=1
  run run_cmd touch "$BATS_TEST_TMPDIR/created"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] touch"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/created" ]
}

# --- confirm ------------------------------------------------------------------

@test "confirm: --yes auto-accepts" {
  ASSUME_YES=1
  confirm "Proceed?"
}

@test "confirm: declines when stdin is not interactive" {
  run confirm "Proceed?" </dev/null
  [ "$status" -eq 1 ]
}

# --- backup_and_copy ----------------------------------------------------------

@test "backup_and_copy: creates missing parent directories" {
  backup_and_copy "$SOURCE_FILE" "$HOME/.config/app/config.toml"
  [ "$(cat "$HOME/.config/app/config.toml")" = "new" ]
  [ ! -e "$BACKUP_DIR" ]
}

@test "backup_and_copy: leaves identical targets untouched" {
  cp "$SOURCE_FILE" "$HOME/.zshrc"
  run backup_and_copy "$SOURCE_FILE" "$HOME/.zshrc"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Unchanged"* ]]
  [ ! -e "$BACKUP_DIR" ]
}

@test "backup_and_copy: backs up a differing target preserving its path" {
  mkdir -p "$HOME/.config/app"
  printf 'old\n' >"$HOME/.config/app/config.toml"
  backup_and_copy "$SOURCE_FILE" "$HOME/.config/app/config.toml"
  [ "$(cat "$HOME/.config/app/config.toml")" = "new" ]
  [ "$(cat "$BACKUP_DIR/.config/app/config.toml")" = "old" ]
}

@test "backup_and_copy: handles paths with spaces" {
  target="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  mkdir -p "$(dirname "$target")"
  printf 'old\n' >"$target"
  backup_and_copy "$SOURCE_FILE" "$target"
  [ "$(cat "$target")" = "new" ]
  [ "$(cat "$BACKUP_DIR/Library/Application Support/com.mitchellh.ghostty/config.ghostty")" = "old" ]
}

@test "backup_and_copy: replaces a symlink with a real file and backs up the link" {
  printf 'linked\n' >"$BATS_TEST_TMPDIR/elsewhere"
  ln -s "$BATS_TEST_TMPDIR/elsewhere" "$HOME/.zshrc"
  backup_and_copy "$SOURCE_FILE" "$HOME/.zshrc"
  [ ! -L "$HOME/.zshrc" ]
  [ "$(cat "$HOME/.zshrc")" = "new" ]
  [ -L "$BACKUP_DIR/.zshrc" ]
  [ "$(cat "$BATS_TEST_TMPDIR/elsewhere")" = "linked" ]
}

@test "backup_and_copy: refuses to overwrite a directory" {
  mkdir -p "$HOME/.zshrc"
  run backup_and_copy "$SOURCE_FILE" "$HOME/.zshrc"
  [ "$status" -eq 1 ]
  [ -d "$HOME/.zshrc" ]
}

@test "backup_and_copy: fails when the source is missing" {
  run backup_and_copy "$BATS_TEST_TMPDIR/missing" "$HOME/.zshrc"
  [ "$status" -eq 1 ]
  [ ! -e "$HOME/.zshrc" ]
}

@test "backup_and_copy: dry-run changes nothing" {
  DRY_RUN=1
  printf 'old\n' >"$HOME/.zshrc"
  run backup_and_copy "$SOURCE_FILE" "$HOME/.zshrc"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.zshrc")" = "old" ]
  [ ! -e "$BACKUP_DIR" ]
}

@test "backup_path_for: paths outside HOME keep their absolute structure" {
  [ "$(backup_path_for "$HOME/.zshrc")" = "$BACKUP_DIR/.zshrc" ]
  [ "$(backup_path_for "/etc/hosts")" = "$BACKUP_DIR/etc/hosts" ]
}

# --- read_manifest ------------------------------------------------------------

@test "read_manifest: skips comments and blanks, trims, keeps spaces inside paths" {
  manifest="$BATS_TEST_TMPDIR/manifest.txt"
  printf '# header\n\n  .zshrc  \n\t# indented comment\nLibrary/Application Support/app/config\n.config/herdr/config.toml' >"$manifest"
  run read_manifest "$manifest"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '.zshrc\nLibrary/Application Support/app/config\n.config/herdr/config.toml')" ]
}

@test "read_manifest: rejects absolute paths and parent traversal" {
  for bad_entry in "/etc/hosts" ".." "../outside" ".config/../../outside" ".config/.."; do
    printf '%s\n' "$bad_entry" >"$BATS_TEST_TMPDIR/manifest.txt"
    run read_manifest "$BATS_TEST_TMPDIR/manifest.txt"
    [ "$status" -eq 1 ]
  done
}

@test "read_manifest: fails when the manifest is missing" {
  run read_manifest "$BATS_TEST_TMPDIR/missing.txt"
  [ "$status" -eq 1 ]
}

@test "read_manifest: the repo manifest is valid" {
  run read_manifest "$REPO_ROOT/manifest.txt"
  [ "$status" -eq 0 ]
}
