# =========================
# PWD Generation
# =========================
function genpass() {
  case $1 in
    uuid) echo $(uuidgen | tr '[:upper:]' '[:lower:]');;
    # `-` goes last: in the middle of a tr set it would define a character range
    strong) echo "$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_=+[]{}<>?,.-' </dev/urandom | head -c 20)";;
    *) openssl rand -base64 50 | tr -d '\n+/=' | sed 's/....../&-/g' | cut -c 1-20;;
  esac
}

# =========================
# Cleanup Function: This function clears various caches and logs on macOS to free up disk space and improve system performance.
# =========================
function cleanup() {
  # Ensure the script runs with root privileges where needed
  echo "=========================================="
  echo "   macOS Safe Cache Cleaning Script       "
  echo "=========================================="
  echo "Close all running applications before proceeding."
  # zsh syntax: `read -p` means "read from coprocess" in zsh and would skip this pause
  read "?Press [Enter] to start cleaning (Ctrl-C to cancel)..." || return 1

  # 1. Clear User Caches
  echo -e "\n--> Cleaning User Caches..."
  rm -rf ~/Library/Caches/*(N)

  # 2. Clear System Caches (Requires Password)
  echo -e "\n--> Cleaning System Caches..."
  # /System/Library/Caches lives on the sealed, read-only system volume: not touched
  sudo rm -rf /Library/Caches/*(N)

  # 3. Clear User Logs
  echo -e "\n--> Cleaning User Logs..."
  rm -rf ~/Library/Logs/*(N)

  # 4. Clear System Logs
  echo -e "\n--> Cleaning System Logs..."
  # /private/var/log is left alone: system services expect its files and folders
  sudo rm -rf /Library/Logs/*(N)

  # 5. Flush DNS Cache
  echo -e "\n--> Flushing DNS Cache..."
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder

  # 6. Clear Apple Font Caches
  echo -e "\n--> Cleaning Font Caches..."
  atsutil databases -remove

  # 7. Clear Xcode Derived Data (Safe for developers)
  if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
      echo -e "\n--> Cleaning Xcode Derived Data..."
      rm -rf ~/Library/Developer/Xcode/DerivedData/*(N)
  fi

  # 8. Clear Homebrew Cache (If installed)
  if command -v brew &> /dev/null; then
      echo -e "\n--> Cleaning Homebrew Cache..."
      brew cleanup -s
      rm -rf "$(brew --cache)"
  fi

  # 9. Purge Inactive Memory
  echo -e "\n--> Purging Inactive Memory..."
  sudo purge

  echo -e "\n=========================================="
  echo "   Done! Please restart your Mac now.     "
  echo "=========================================="
}

# =========================
# Gmain Function: This function automates the process of updating a Git repository by checking for uncommitted changes, switching to the main or master branch, pulling the latest updates, and restoring any stashed changes.
# =========================
function gmain() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Error: This directory is not a Git repository."
    return 1
  fi
  local changes_stashed=false
  local target_branch
  if ! git diff-index --quiet HEAD --; then
    echo "📦 Saving your uncommitted changes via 'git stash'..."
    git stash
    changes_stashed=true
  fi
  if git show-ref --verify --quiet refs/heads/main; then
    target_branch="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    target_branch="master"
  else
    echo "❌ Error: Could not find a local 'main' or 'master' branch."
    return 1
  fi
  echo "🌿 Switching to branch: $target_branch..."
  git checkout "$target_branch"
  echo "📥 Fetching and pulling the latest updates..."
  git pull origin "$target_branch"
  if [ "$changes_stashed" = true ]; then
    echo "🔺 Restoring your uncommitted changes via 'git stash pop'..."
    git stash pop || echo "⚠️ Warning: Could not pop stash automatically due to a conflict. Your changes are safely stored in 'git stash list'."
  fi
  echo "✅ Successfully updated $target_branch!"
}