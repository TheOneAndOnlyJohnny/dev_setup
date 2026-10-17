#!/usr/bin/env bash
# Publishes the docs site to GitHub Pages: ./scripts/deploy-docs.sh [--dry-run]
# Creates the docs venv if missing, installs requirements-docs.txt, builds with --strict and
# runs `mkdocs gh-deploy --force`, which pushes the gh-pages branch. --dry-run stops after the build.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Overridable so tests can point at a fixture repo and a fake venv.
DOCS_ROOT="${DOCS_ROOT:-$REPO_ROOT}"
VENV_DIR="${VENV_DIR:-$DOCS_ROOT/.venv}"
# Material prints a MkDocs 2.0 notice on every run; the pinned version requires MkDocs 1.x.
export NO_MKDOCS_2_WARNING=true

# shellcheck source=lib/log.sh
source "$REPO_ROOT/lib/log.sh"
# shellcheck source=lib/utils.sh
source "$REPO_ROOT/lib/utils.sh"

show_help() {
  cat <<'EOF'
Usage: ./scripts/deploy-docs.sh [--dry-run]

Builds the docs site with --strict and publishes it to GitHub Pages (gh-pages branch).

  --dry-run   Build only; print the deploy command without pushing
  -h, --help  Show this help
EOF
}

parse_deploy_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      -h | --help) SHOW_HELP=1 ;;
      *)
        log_error "Unknown option: $1"
        return 1
        ;;
    esac
    shift
  done
}

# The published site must match committed docs, not local edits.
assert_docs_committed() {
  local pending_changes
  pending_changes="$(git -C "$DOCS_ROOT" status --porcelain -- docs mkdocs.yml requirements-docs.txt)"
  if [[ -n "$pending_changes" ]]; then
    log_error "Uncommitted docs changes. Commit them first so the site matches the repo:"
    printf '%s\n' "$pending_changes" >&2
    return 1
  fi
}

ensure_docs_venv() {
  if [[ ! -x "$VENV_DIR/bin/mkdocs" ]]; then
    log_info "Creating docs venv at $VENV_DIR"
    python3 -m venv "$VENV_DIR"
  fi
  "$VENV_DIR/bin/pip" install --quiet --disable-pip-version-check -r "$DOCS_ROOT/requirements-docs.txt"
  log_success "Docs tooling ready"
}

build_docs() {
  log_info "Building the site (--strict)"
  "$VENV_DIR/bin/mkdocs" build --strict --config-file "$DOCS_ROOT/mkdocs.yml"
  log_success "Site built"
}

deploy_docs() {
  log_info "Publishing to the gh-pages branch"
  (cd "$DOCS_ROOT" && run_cmd "$VENV_DIR/bin/mkdocs" gh-deploy --force --config-file "$DOCS_ROOT/mkdocs.yml")
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_warn "Dry run: nothing was pushed"
    return 0
  fi
  log_success "Published. GitHub Pages updates in a minute or two"
}

main() {
  parse_deploy_flags "$@"
  if [[ "$SHOW_HELP" -eq 1 ]]; then
    show_help
    return 0
  fi
  assert_docs_committed
  ensure_docs_venv
  build_docs
  deploy_docs
}

main "$@"
