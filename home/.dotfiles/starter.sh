# Set up vars
export EDITOR="code --wait"
export VISUAL="code --wait"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export GOPATH=$HOME/go
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
export ZSH_THEME="powerlevel10k/powerlevel10k"
export HOMEBREW_NO_AUTO_UPDATE=1
export PATH="$HOME/.local/bin:$PATH"
export HOMEBREW_NO_ASK=1
# mysql-client is keg-only, so Homebrew doesn't link it into PATH
export PATH="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/mysql-client/bin:$PATH"

plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    you-should-use
    zsh-completions
    zsh-history-substring-search
    jsontools
)

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

source $ZSH/oh-my-zsh.sh

# Set Aliases
source ~/.dotfiles/setup_aliases.sh
source ~/.dotfiles/setup_functions.sh
source ~/.dotfiles/setup_keybindings.sh

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

clear
