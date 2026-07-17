#!/usr/bin/env bash
# bootstrap.sh — Phase 0 of the install workflow.
#
# Gets a bare machine to the point where prep (Phase 1) can run: ensures
# git + zsh exist, clones the (public) dotfiles over https WITHOUT submodules
# (private submodules need auth, which prep establishes), then hands off.
#
# dotfiles is cloned into the bare + worktree layout (like every other repo):
#   ~/projects/bare/dotfiles.git          bare repo
#   ~/projects/worktree/dotfiles/main     main worktree (stow source, prep runs here)
# so you can `wt add feature/x` and work dotfiles across multiple worktrees while
# the $HOME symlinks always stow from main.
#
# Run on a fresh machine:
#   curl -fsSL https://raw.githubusercontent.com/eduuh/dotfiles/main/bootstrap.sh | bash
#
# Optional: pass a profile through to prep, e.g.
#   curl -fsSL .../bootstrap.sh | bash -s -- --profile core
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/eduuh/dotfiles.git}"
PROJECT_ROOT="${PROJECT_ROOT:-$HOME/projects}"
DOTFILES_BARE="$PROJECT_ROOT/bare/dotfiles.git"
DOTFILES_MAIN="$PROJECT_ROOT/worktree/dotfiles/main"

log() { printf '\033[1;36m[bootstrap]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[bootstrap]\033[0m %s\n' "$*" >&2; }

# Resolve the package manager just well enough to install git/zsh/curl.
detect_pm() {
  if [ -f /run/ostree-booted ] && command -v rpm-ostree >/dev/null 2>&1; then echo rpm-ostree
  elif command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v dnf     >/dev/null 2>&1; then echo dnf
  elif command -v pacman  >/dev/null 2>&1; then echo pacman
  elif command -v brew    >/dev/null 2>&1; then echo brew
  elif [ "$(uname)" = "Darwin" ]; then echo mac
  else echo unknown
  fi
}

# ensure_pkg <command> <package> — install only if the command is missing.
ensure_pkg() {
  command -v "$1" >/dev/null 2>&1 && return 0
  log "installing $2…"
  case "$(detect_pm)" in
    apt)        sudo apt-get update -y && sudo apt-get install -y "$2" ;;
    dnf)        sudo dnf install -y "$2" ;;
    rpm-ostree) sudo rpm-ostree install --idempotent --allow-inactive --apply-live -y "$2" ;;
    pacman)     sudo pacman -S --noconfirm "$2" ;;
    brew)       brew install "$2" ;;
    mac)        err "Xcode Command Line Tools needed for '$1'. Run: xcode-select --install"; exit 1 ;;
    *)          err "No supported package manager found to install '$2'."; exit 1 ;;
  esac
}

main() {
  log "Phase 0 — bootstrap"

  ensure_pkg curl curl
  ensure_pkg git  git
  ensure_pkg zsh  zsh

  if [ -e "$DOTFILES_MAIN/prep.sh" ]; then
    log "dotfiles worktree already present at $DOTFILES_MAIN — skipping clone"
  else
    log "cloning dotfiles → bare + worktree (https, no submodules)"
    mkdir -p "$(dirname "$DOTFILES_BARE")" "$(dirname "$DOTFILES_MAIN")"
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_BARE"
    # Track all branches so `wt add` can check out any of them later.
    git --git-dir="$DOTFILES_BARE" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git --git-dir="$DOTFILES_BARE" fetch origin
    local def
    def=$(git --git-dir="$DOTFILES_BARE" symbolic-ref --short HEAD 2>/dev/null || echo main)
    git --git-dir="$DOTFILES_BARE" worktree add "$PROJECT_ROOT/worktree/dotfiles/$def" "$def"
    DOTFILES_MAIN="$PROJECT_ROOT/worktree/dotfiles/$def"
  fi

  log "handing off to prep (Phase 1)…"
  # Restore a real TTY for prep's interactive prompts (curl | bash leaves stdin
  # on the pipe). Fall back to a plain exec where there's no controlling tty.
  if [ -e /dev/tty ]; then
    exec zsh "$DOTFILES_MAIN/prep.sh" "$@" < /dev/tty
  else
    exec zsh "$DOTFILES_MAIN/prep.sh" "$@"
  fi
}

main "$@"
