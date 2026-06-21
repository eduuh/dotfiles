#!/usr/bin/env zsh
# prep.sh — Phase 1 of the install workflow: the short, ATTENDED phase.
#
# Everything that needs a human lives here — sudo, GitHub sign-in + SSH key,
# profile selection — so the long install (Phase 2) can run fully unattended.
# After prep writes its "ready" marker, you can walk away from setup.sh.
#
#   ./prep.sh [--profile core|dev|desktop]
#
# Not `set -e`: this phase collects failures (like setup.sh) rather than aborting.
set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/.bin/setup/common.sh"

STATE_DIR="$HOME/.local/state/dotfiles"
READY_MARKER="$STATE_DIR/ready"

# Refine detect_distro() into the four install targets + termux.
detect_target() {
  case "$(detect_distro)" in
    codespace) echo codespace ;;
    darwin)    echo mac ;;
    termux)    echo termux ;;
    *)         if _is_wsl; then echo wsl; else echo linux; fi ;;
  esac
}

# Default profile per target (overridable with --profile / $PROFILE).
default_profile() {
  case "$1" in
    codespace|wsl) echo dev ;;
    linux|mac)     echo desktop ;;
    termux)        echo core ;;
    *)             echo dev ;;
  esac
}

main() {
  local target profile="" arg_profile="" run_setup=true

  # --- parse args ---
  #   --profile <tier>  override the profile (core|dev|desktop)
  #   --prep-only       stop after prep; don't chain into setup.sh
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)   arg_profile="$2"; shift 2 ;;
      --profile=*) arg_profile="${1#*=}"; shift ;;
      --prep-only) run_setup=false; shift ;;
      *)           shift ;;
    esac
  done

  target=$(detect_target)
  profile="${arg_profile:-${PROFILE:-$(default_profile "$target")}}"

  echo "────────────────────────────────────────"
  echo " Phase 1 · prep   target=$target  profile=$profile"
  echo "────────────────────────────────────────"

  # 1. Cache sudo credentials so Phase 2 never prompts. Skip on codespace / root.
  if [[ "$target" != "codespace" && "${EUID:-$(id -u)}" != "0" ]]; then
    echo "→ Caching sudo credentials (you may be prompted once)…"
    sudo -v || track_failure "sudo" "Failed to acquire sudo credentials"
  fi

  # 2. GitHub auth + SSH key — the part that needs you. Codespaces are pre-authed.
  if [[ "$target" == "codespace" ]]; then
    echo "→ Codespace detected — GitHub auth already provided, skipping gh-keys."
  elif [[ -x "$SCRIPT_DIR/.bin/gh-keys" ]]; then
    echo "→ Setting up GitHub CLI + SSH keys…"
    "$SCRIPT_DIR/.bin/gh-keys" || track_failure "github" "gh-keys failed"
  else
    track_failure "github" "gh-keys not found at $SCRIPT_DIR/.bin/gh-keys"
  fi

  # 3. Record the resolved target + profile for the unattended install to read.
  mkdir -p "$STATE_DIR"
  {
    echo "TARGET=$target"
    echo "PROFILE=$profile"
  } > "$READY_MARKER"
  echo "→ Wrote $READY_MARKER"

  print_failure_summary

  if [[ "$run_setup" != "true" ]]; then
    echo ""
    echo "Prep complete (--prep-only). Run the unattended install when ready:"
    echo "    cd $SCRIPT_DIR && ./setup.sh"
    return 0
  fi

  echo ""
  echo "Prep complete — the interactive part is done. Handing off to the"
  echo "unattended install (setup.sh); walk away, it won't prompt."
  echo ""
  exec zsh "$SCRIPT_DIR/setup.sh" --profile "$profile"
}

main "$@"
