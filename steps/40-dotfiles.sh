# shellcheck shell=bash
# Copies every file listed in manifest.txt from home/ into $HOME. Identical files are skipped;
# files that differ are backed up to $BACKUP_DIR before being replaced (see backup_and_copy).
# Claude Code files have their own manifest, copied by the claude step.

DOTFILES_MANIFEST="${DOTFILES_MANIFEST:-$REPO_ROOT/manifest.txt}"
DOTFILES_SOURCE_DIR="${DOTFILES_SOURCE_DIR:-$REPO_ROOT/home}"

copy_manifest_files "$DOTFILES_MANIFEST" "$DOTFILES_SOURCE_DIR"
