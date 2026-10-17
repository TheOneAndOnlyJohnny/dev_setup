#!/usr/bin/env bats
# Repository invariants: manifest ↔ home/ consistency, portability, shell syntax and docs.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export NO_COLOR=1
  # shellcheck source=../lib/log.sh
  source "$REPO_ROOT/lib/log.sh"
  # shellcheck source=../lib/utils.sh
  source "$REPO_ROOT/lib/utils.sh"
}

# Pages listed in the mkdocs.yml nav (one per line: `- Title: page.md` or `- page.md`).
read_mkdocs_nav_pages() {
  sed -nE '/^nav:/,$ s/^[[:space:]]*- ([^:]*: )?([^[:space:]]+\.md)[[:space:]]*$/\2/p' "$REPO_ROOT/mkdocs.yml"
}

# Entries of every manifest (manifest.txt + manifest.claude.txt).
read_all_manifests() {
  read_manifest "$REPO_ROOT/manifest.txt"
  read_manifest "$REPO_ROOT/manifest.claude.txt"
}

@test "every manifest entry exists under home/" {
  [ -n "$(read_manifest "$REPO_ROOT/manifest.claude.txt")" ]
  local entry missing=""
  while IFS= read -r entry; do
    if [[ ! -f "$REPO_ROOT/home/$entry" ]]; then
      missing+="$entry "
    fi
  done < <(read_all_manifests)
  [ -z "$missing" ] || { echo "Missing under home/: $missing"; false; }
}

@test "every file under home/ is listed in the manifest" {
  local file_path relative_path unlisted=""
  local manifest_entries
  manifest_entries="$(read_all_manifests)"
  while IFS= read -r file_path; do
    relative_path="${file_path#"$REPO_ROOT/home/"}"
    if ! grep -qxF "$relative_path" <<<"$manifest_entries"; then
      unlisted+="$relative_path "
    fi
  done < <(find "$REPO_ROOT/home" -type f ! -name .DS_Store)
  [ -z "$unlisted" ] || { echo "Not in manifest: $unlisted"; false; }
}

@test "home/ has no hardcoded user paths" {
  run grep -rnE '/Users/[A-Za-z]' "$REPO_ROOT/home"
  [ "$status" -eq 1 ] || { echo "$output"; false; }
}

@test "zsh files under home/ have valid syntax" {
  if ! command -v zsh >/dev/null; then
    skip "zsh not installed"
  fi
  local zsh_file
  for zsh_file in "$REPO_ROOT"/home/.dotfiles/*.sh "$REPO_ROOT"/home/.zshrc "$REPO_ROOT"/home/.zprofile "$REPO_ROOT"/home/.p10k.zsh; do
    zsh -n "$zsh_file" || { echo "Syntax error: $zsh_file"; false; }
  done
}

@test "Ghostty config is valid" {
  local ghostty_binary
  ghostty_binary="$(command -v ghostty || echo /Applications/Ghostty.app/Contents/MacOS/ghostty)"
  if [[ ! -x "$ghostty_binary" ]]; then
    skip "ghostty not installed"
  fi
  run "$ghostty_binary" +validate-config --config-file="$REPO_ROOT/home/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  [ "$status" -eq 0 ] || { echo "$output"; false; }
}

@test "Claude Code settings.json is valid JSON without private keys" {
  python3 - "$REPO_ROOT/home/.claude/settings.json" <<'PY'
import json, sys
settings = json.load(open(sys.argv[1]))
leaked = {"autoMode", "hooks", "env", "apiKeyHelper"} & settings.keys()
sys.exit(f"private keys in settings.json: {sorted(leaked)}" if leaked else 0)
PY
}

@test "docs/claude-code.md documents every CLAUDE.md rule and settings.json key" {
  local doc_file="$REPO_ROOT/docs/claude-code.md"
  local rule_name setting_key undocumented=""
  while IFS= read -r rule_name; do
    grep -qxF "#### $rule_name" "$doc_file" || grep -qF "**$rule_name**" "$doc_file" || undocumented+="[$rule_name] "
  done < <(sed -nE 's/^- \*\*([^*]+):\*\*.*/\1/p' "$REPO_ROOT/home/.claude/CLAUDE.md")
  while IFS= read -r setting_key; do
    grep -qF "| \`$setting_key\` |" "$doc_file" || undocumented+="[$setting_key] "
  done < <(python3 -c 'import json, sys; print("\n".join(json.load(open(sys.argv[1]))))' "$REPO_ROOT/home/.claude/settings.json")
  [ -z "$undocumented" ] || { echo "Undocumented: $undocumented"; false; }
}

@test "every docs page is in the mkdocs.yml nav and every nav page exists" {
  local nav_pages page mismatched=""
  nav_pages="$(read_mkdocs_nav_pages)"
  [ -n "$nav_pages" ]
  while IFS= read -r page; do
    [[ -f "$REPO_ROOT/docs/$page" ]] || mismatched+="[missing file: $page] "
  done <<< "$nav_pages"
  while IFS= read -r page; do
    grep -qxF "$page" <<< "$nav_pages" || mismatched+="[not in nav: $page] "
  done < <(cd "$REPO_ROOT/docs" && find . -name '*.md' | sed 's|^\./||')
  [ -z "$mismatched" ] || { echo "Docs ↔ nav mismatch: $mismatched"; false; }
}

@test "docs code blocks titled with a ~/ path match that file under home/" {
  run python3 - "$REPO_ROOT" <<'PY'
import pathlib, re, sys
repo_root = pathlib.Path(sys.argv[1])
block_pattern = re.compile(r'^```\S* title="~/([^"]+)"\n(.*?)^```$', re.M | re.S)
checked_blocks, mismatches = 0, []
for doc_file in sorted((repo_root / "docs").rglob("*.md")):
    for match in block_pattern.finditer(doc_file.read_text()):
        checked_blocks += 1
        home_file = repo_root / "home" / match[1]
        if not home_file.is_file():
            mismatches.append(f"{doc_file.name}: ~/{match[1]} is not under home/")
        elif match[2].rstrip("\n") != home_file.read_text().rstrip("\n"):
            mismatches.append(f"{doc_file.name}: ~/{match[1]} differs from home/")
print("\n".join(mismatches) or f"{checked_blocks} blocks match")
sys.exit(1 if mismatches or checked_blocks == 0 else 0)
PY
  [ "$status" -eq 0 ] || { echo "$output"; false; }
}
