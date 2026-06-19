#!/usr/bin/env bash
# bootstrap.sh — Phase 0 of the install workflow.
#
# Gets a bare machine to the point where prep (Phase 1) can run: ensures
# git + zsh exist, clones the (public) dotfiles over https WITHOUT submodules
# (private submodules need auth, which prep establishes), then hands off.
#
# Run on a fresh machine:
#   curl -fsSL https://raw.githubusercontent.com/eduuh/dotfiles/main/bootstrap.sh | bash
#
# Optional: pass a profile through to prep, e.g.
#   curl -fsSL .../bootstrap.sh | bash -s -- --profile core
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/eduuh/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/dotfiles}"

log() { printf '\033[1;36m[bootstrap]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[bootstrap]\033[0m %s\n' "$*" >&2; }

# Resolve the package manager just well enough to install git/zsh/curl.
detect_pm() {
  if command -v apt-get >/dev/null 2>&1; then echo apt
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
    apt)    sudo apt-get update -y && sudo apt-get install -y "$2" ;;
    pacman) sudo pacman -S --noconfirm "$2" ;;
    brew)   brew install "$2" ;;
    mac)    err "Xcode Command Line Tools needed for '$1'. Run: xcode-select --install"; exit 1 ;;
    *)      err "No supported package manager found to install '$2'."; exit 1 ;;
  esac
}

main() {
  log "Phase 0 — bootstrap"

  ensure_pkg curl curl
  ensure_pkg git  git
  ensure_pkg zsh  zsh

  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "dotfiles already present at $DOTFILES_DIR — skipping clone"
  else
    log "cloning dotfiles → $DOTFILES_DIR (https, no submodules)"
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi

  log "handing off to prep (Phase 1)…"
  # Restore a real TTY for prep's interactive prompts (curl | bash leaves stdin
  # on the pipe). Fall back to a plain exec where there's no controlling tty.
  if [ -e /dev/tty ]; then
    exec zsh "$DOTFILES_DIR/prep.sh" "$@" < /dev/tty
  else
    exec zsh "$DOTFILES_DIR/prep.sh" "$@"
  fi
}

main "$@"
