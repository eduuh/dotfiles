# Basic Path Setup
export PATH="$HOME/.bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Homebrew Setup
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # Add GNU coreutils to PATH
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    alias kanata-restart="sudo launchctl unload /Library/LaunchDaemons/com.custom.kanata.plist && sudo launchctl load /Library/LaunchDaemons/com.custom.kanata.plist"
    alias kanata-log="cat /tmp/kanata.out /tmp/kanata.err"

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
alias po="$HOME/.bin/pkg-open.sh"
alias nvimd='nvim -c "DiffviewOpen origin/main"'
alias bn="$HOME/.bin/bn.sh"

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Load Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Load FZF
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# Load Lazy Load
[ -f "$HOME/projects/dotfiles/.zsh_lazy_load" ] && source "$HOME/projects/dotfiles/.zsh_lazy_load"

[ -f "$HOME/projects/personal-notes/scripts/ws.zsh" ] && source "$HOME/projects/personal-notes/scripts/ws.zsh"

# pnpm
export PNPM_HOME="/Users/edd/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# Tmux integration: Update current path for splits/windows
if [ -n "$TMUX" ]; then
  _tmux_refresh_path() {
    tmux refresh-client -S 2>/dev/null
  }
  chpwd_functions+=(_tmux_refresh_path)
fi

# Zoxide (smart cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Worktree manager wrapper (wt go needs to cd in current shell)
wt() {
    if [[ "$1" == "go" ]]; then
        local dir
        dir=$("$HOME/.bin/wt" go "${@:2}")
        [[ -n "$dir" && -d "$dir" ]] && cd "$dir"
    else
        "$HOME/.bin/wt" "$@"
    fi
}

# Branch note quick-add
t() { "$HOME/.bin/bn" add todo "$*" }
unalias r 2>/dev/null  # override zsh's default r=fc (repeat last command)
r() { "$HOME/.bin/bn" add research "$*" }
c() { "$HOME/.bin/bn" add collab "$*" }
a() { "$HOME/.bin/bn" add ask "$*" }

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export KUBECONFIG=/Users/edd/projects/kube/kubeconfig.local

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Starship
eval "$(starship init zsh)"
