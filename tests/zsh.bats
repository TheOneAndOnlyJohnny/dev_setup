#!/usr/bin/env bats
# Tests for steps/30-zsh.sh with a fake git whose `clone` records the call and creates <dest>/.git.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HOME="$BATS_TEST_TMPDIR/home"
  export NO_COLOR=1
  export SHELL=/bin/zsh
  export TRACE_FILE="$BATS_TEST_TMPDIR/trace"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$HOME" "$FAKE_BIN"
  : >"$TRACE_FILE"
  cat >"$FAKE_BIN/git" <<'EOF'
#!/bin/bash
destination="${@: -1}"
repository="${@: -2:1}"
echo "clone $repository ${destination#"$HOME"/}" >>"$TRACE_FILE"
if [ "${FAKE_GIT_FAIL:-0}" = "1" ]; then exit 128; fi
mkdir -p "$destination/.git"
EOF
  chmod +x "$FAKE_BIN/git"
}

run_zsh_step() {
  run env PATH="$FAKE_BIN:/usr/bin:/bin" /bin/bash -c "
    set -euo pipefail
    source '$REPO_ROOT/lib/log.sh'
    source '$REPO_ROOT/lib/utils.sh'
    parse_flags $*
    source '$REPO_ROOT/steps/30-zsh.sh'
  "
}

@test "fresh install clones oh-my-zsh first, then theme and plugins into custom/" {
  run_zsh_step
  [ "$status" -eq 0 ]
  [ "$(wc -l <"$TRACE_FILE" | tr -d ' ')" -eq 7 ]
  [ "$(head -1 "$TRACE_FILE")" = "clone https://github.com/ohmyzsh/ohmyzsh.git .oh-my-zsh" ]
  grep -qx "clone https://github.com/romkatv/powerlevel10k.git .oh-my-zsh/custom/themes/powerlevel10k" "$TRACE_FILE"
  grep -qx "clone https://github.com/zsh-users/zsh-autosuggestions.git .oh-my-zsh/custom/plugins/zsh-autosuggestions" "$TRACE_FILE"
}

@test "second run is idempotent: nothing is cloned again" {
  run_zsh_step
  : >"$TRACE_FILE"
  run_zsh_step
  [ "$status" -eq 0 ]
  [ ! -s "$TRACE_FILE" ]
  [[ "$output" == *"Present: .oh-my-zsh/custom/themes/powerlevel10k"* ]]
}

@test "a non-git directory in the way fails without clobbering it" {
  mkdir -p "$HOME/.oh-my-zsh"
  echo "mine" >"$HOME/.oh-my-zsh/file"
  run_zsh_step
  [ "$status" -eq 1 ]
  [[ "$output" == *"exists but is not a git clone"* ]]
  [ "$(cat "$HOME/.oh-my-zsh/file")" = "mine" ]
}

@test "a failed clone fails the step" {
  export FAKE_GIT_FAIL=1
  run_zsh_step
  [ "$status" -ne 0 ]
}

@test "dry-run prints clones without running them" {
  run_zsh_step --dry-run
  [ "$status" -eq 0 ]
  [ ! -s "$TRACE_FILE" ]
  [[ "$output" == *"[dry-run] git clone --quiet --depth=1 https://github.com/ohmyzsh/ohmyzsh.git"* ]]
}

@test "warns when the login shell is not zsh" {
  export SHELL=/bin/bash
  run_zsh_step
  [ "$status" -eq 0 ]
  [[ "$output" == *"chsh -s /bin/zsh"* ]]
}

@test "starter.sh plugins are either OMZ built-ins or cloned by the step" {
  local builtin_plugins=" git jsontools "
  local cloned_plugins plugin missing=""
  cloned_plugins=" $(grep -oE 'plugins/[^|]+' "$REPO_ROOT/steps/30-zsh.sh" | sed 's|plugins/||' | tr '\n' ' ') "
  for plugin in $(sed -n '/^plugins=(/,/^)/p' "$REPO_ROOT/home/.dotfiles/starter.sh" | sed '1d;$d'); do
    if [[ "$builtin_plugins" != *" $plugin "* && "$cloned_plugins" != *" $plugin "* ]]; then
      missing+="$plugin "
    fi
  done
  [ -z "$missing" ] || { echo "Not installed by 30-zsh: $missing"; false; }
  grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$REPO_ROOT/home/.dotfiles/starter.sh"
}
