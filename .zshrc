# Basic Path Setup
export PATH="$HOME/projects/dotfiles/.bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Homebrew Setup
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # Add GNU coreutils to PATH
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    # Add GNU coreutils to PATH
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias yolo='claude --dangerously-skip-permissions'

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Load Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Load FZF
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# Load Lazy Load
[ -f "$HOME/projects/dotfiles/.zsh_lazy_load" ] && source "$HOME/projects/dotfiles/.zsh_lazy_load"

# pnpm
export PNPM_HOME="/Users/edd/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/Users/edd/yes/_bun" ] && source "/Users/edd/yes/_bun"

# bun
export BUN_INSTALL="yes"
export PATH="$BUN_INSTALL/bin:$PATH"

# Starship
eval "$(starship init zsh)"

# Zoxide (smart cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Kanata
alias kanata-restart="sudo launchctl unload /Library/LaunchDaemons/com.custom.kanata.plist && sudo launchctl load /Library/LaunchDaemons/com.custom.kanata.plist"
alias kanata-log="cat /tmp/kanata.out /tmp/kanata.err"
# bun
export BUN_INSTALL="yes"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export KUBECONFIG=/Users/edd/projects/kube/kubeconfig.local

. "$HOME/.local/bin/env"

# Git worktree workflow (works with any bare repo project)
# wt-new, wt-delete, wt-list, wt-prune are in .bin
# Shell functions for commands that need to change directory:
wt-cd() {
    local target=$(command wt-cd "$@" 2>/dev/null)
    if [ -n "$target" ] && [ -d "$target" ]; then
        cd "$target"
    else
        command wt-cd "$@"
    fi
}
wt-start() {
    local target=$(command wt-start "$@")
    if [ -n "$target" ] && [ -d "$target" ]; then
        cd "$target"
    fi
}
# Aliases
alias wtl="wt-list"
alias wtn="wt-new"
alias wtd="wt-delete"
alias wts="wt-start"
alias wtp="wt-prune"
