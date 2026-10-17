#!/usr/bin/env bats
# Tests for scripts/deploy-docs.sh against a fixture git repo, with fake python3/pip/mkdocs
# that record their calls.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export NO_COLOR=1
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  export DOCS_ROOT="$BATS_TEST_TMPDIR/repo"
  export VENV_DIR="$BATS_TEST_TMPDIR/venv"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$FAKE_BIN" "$DOCS_ROOT/docs"
  : >"$TRACE_FILE"
  printf 'site_name: test\n' >"$DOCS_ROOT/mkdocs.yml"
  printf 'mkdocs-material==9.7.7\n' >"$DOCS_ROOT/requirements-docs.txt"
  printf '# Home\n' >"$DOCS_ROOT/docs/index.md"
  git -C "$DOCS_ROOT" init --quiet
  git -C "$DOCS_ROOT" add .
  git -C "$DOCS_ROOT" -c user.name=test -c user.email=test@example.com commit --quiet -m init
  # Fake `python3 -m venv <dir>`: creates a venv whose pip/mkdocs log their arguments.
  # FAKE_BUILD_FAILS=1 makes `mkdocs build` fail.
  cat >"$FAKE_BIN/python3" <<'STUB'
#!/bin/bash
echo "python3 $*" >>"$TRACE_FILE"
venv_dir="$3"
mkdir -p "$venv_dir/bin"
printf '#!/bin/bash\necho "pip $*" >>"$TRACE_FILE"\n' >"$venv_dir/bin/pip"
cat >"$venv_dir/bin/mkdocs" <<'MKDOCS'
#!/bin/bash
echo "mkdocs $1 $2 cwd=$PWD" >>"$TRACE_FILE"
[[ "$1" != build || "${FAKE_BUILD_FAILS:-0}" != 1 ]]
MKDOCS
chmod +x "$venv_dir/bin/pip" "$venv_dir/bin/mkdocs"
STUB
  chmod +x "$FAKE_BIN/python3"
}

run_deploy() {
  run env PATH="$FAKE_BIN:/usr/bin:/bin" /bin/bash "$REPO_ROOT/scripts/deploy-docs.sh" "$@"
}

# Fails when the trace has a matching line. A bare `! grep` mid-test would not fail it:
# bats' errexit ignores negated commands.
refute_trace() {
  ! grep -q "$1" "$TRACE_FILE"
}

trace_commands() {
  sed -E 's/ cwd=.*//; s/ -r .*//' "$TRACE_FILE"
}

@test "creates the venv, installs requirements, builds strict and deploys with --force" {
  run_deploy
  [ "$status" -eq 0 ]
  [ "$(trace_commands)" = "$(printf 'python3 -m venv %s\npip install --quiet --disable-pip-version-check\nmkdocs build --strict\nmkdocs gh-deploy --force' "$VENV_DIR")" ]
}

@test "gh-deploy runs from the docs repo root" {
  run_deploy
  [ "$status" -eq 0 ]
  grep -qxF "mkdocs gh-deploy --force cwd=$DOCS_ROOT" "$TRACE_FILE"
}

@test "an existing venv is reused" {
  run env PATH="$FAKE_BIN:/usr/bin:/bin" python3 -m venv "$VENV_DIR"
  : >"$TRACE_FILE"
  run_deploy
  [ "$status" -eq 0 ]
  refute_trace '^python3'
  grep -q '^pip install' "$TRACE_FILE"
}

@test "--dry-run builds but does not deploy" {
  run_deploy --dry-run
  [ "$status" -eq 0 ]
  grep -q '^mkdocs build --strict' "$TRACE_FILE"
  refute_trace 'gh-deploy'
  [[ "$output" == *"[dry-run]"*"gh-deploy --force"* ]]
}

@test "uncommitted docs changes abort before building" {
  printf 'edited\n' >>"$DOCS_ROOT/docs/index.md"
  run_deploy
  [ "$status" -eq 1 ]
  [[ "$output" == *"Uncommitted docs changes"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "changes outside the docs do not block the deploy" {
  printf 'notes\n' >"$DOCS_ROOT/scratch.txt"
  run_deploy
  [ "$status" -eq 0 ]
  grep -q 'gh-deploy' "$TRACE_FILE"
}

@test "a failed build does not deploy" {
  FAKE_BUILD_FAILS=1 run_deploy
  [ "$status" -ne 0 ]
  refute_trace 'gh-deploy'
}

@test "unknown options fail before doing anything" {
  run_deploy --push
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --push"* ]]
  [ ! -s "$TRACE_FILE" ]
}

@test "--help prints usage without doing anything" {
  run_deploy --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: ./scripts/deploy-docs.sh"* ]]
  [ ! -s "$TRACE_FILE" ]
}
