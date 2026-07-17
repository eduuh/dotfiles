#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/.bin/setup/common.sh"

# --- flags ---
#   --force          re-run every step
#   --profile <tier> override the profile from the prep marker (core|dev|desktop)
#   --work           also install work-machine tools (agency, etc.)
#   reset            clear recorded step state and exit
SETUP_PROFILE_OVERRIDE=""
SETUP_WORK=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)     SETUP_FORCE=true; shift ;;
        --profile)   SETUP_PROFILE_OVERRIDE="$2"; shift 2 ;;
        --profile=*) SETUP_PROFILE_OVERRIDE="${1#*=}"; shift ;;
        --work)      SETUP_WORK=true; shift ;;
        reset)       reset_steps; exit 0 ;;
        *)           shift ;;
    esac
done

# --- Phase 2: the unattended install. Phase 1 (prep) must have run first. ---
READY_MARKER="$HOME/.local/state/dotfiles/ready"
if [[ ! -f "$READY_MARKER" ]]; then
    echo "No prep marker at $READY_MARKER — the interactive Phase 1 hasn't run."
    echo "Run it first:   ./prep.sh"
    echo "(fresh machine: curl -fsSL https://raw.githubusercontent.com/eduuh/dotfiles/main/bootstrap.sh | bash)"
    exit 1
fi
source "$READY_MARKER"   # sets TARGET, PROFILE
PROFILE="${SETUP_PROFILE_OVERRIDE:-$PROFILE}"   # --profile wins over the marker
echo "Phase 2 · install   target=${TARGET:-?}  profile=${PROFILE:-?}"

# prep cached sudo; keep it alive WITHOUT prompting. Bail if it has lapsed so the
# long install never blocks on a password. Skipped on codespace / root.
SUDO_PID=""
if [[ "$TARGET" != "codespace" && "${EUID:-$(id -u)}" != "0" ]]; then
    if ! sudo -n true 2>/dev/null; then
        echo "sudo credentials not cached — re-run ./prep.sh, then ./setup.sh."
        exit 1
    fi
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_PID=$!
fi

# Project cloning is the slowest part of setup (a large work repo can take hours), and
# nothing else depends on it — so never wait on it. Open the clone as a tmux WINDOW and let
# setup.sh finish: it runs in the session setup.sh was launched from, or — when setup.sh
# isn't inside tmux — in the persistent `planning` session (created if absent). The runner
# (setup-projects.sh) records the `projects` step on completion, so a later run skips it.
_PROJECTS_LOG="${SETUP_STATE_DIR:-$HOME/.local/state/dotfiles}/projects-clone.log"
_PROJECTS_WINDOW="bn-clone"
_PLANNING_SESSION="planning"

_projects_launch() {
    if [[ "$SETUP_FORCE" != "true" ]] && _step_is_done projects; then
        echo "✓ [projects] already done — skipping"
        return 0
    fi
    local runner="$SCRIPT_DIR/setup-projects.sh"

    # No tmux at all: detach with nohup so the clone survives setup.sh exiting.
    if ! command -v tmux >/dev/null 2>&1; then
        mkdir -p "$(dirname "$_PROJECTS_LOG")"
        nohup "$runner" > "$_PROJECTS_LOG" 2>&1 < /dev/null &
        echo "→ [projects] cloning in background (no tmux; log: $_PROJECTS_LOG) — setup won't wait."
        return 0
    fi

    # Target the session setup.sh runs in; otherwise the persistent planning session.
    local target
    if [[ -n "$TMUX" ]]; then
        target=$(tmux display-message -p '#S')
    else
        target="$_PLANNING_SESSION"
        tmux has-session -t "$target" 2>/dev/null || tmux new-session -d -s "$target"
    fi

    # Don't open a second clone window if one is already running in that session.
    if tmux list-windows -t "$target" -F '#W' 2>/dev/null | grep -qx "$_PROJECTS_WINDOW"; then
        echo "↻ [projects] clone window '$_PROJECTS_WINDOW' already open in '$target' — leaving it"
        return 0
    fi

    tmux new-window -d -t "$target" -n "$_PROJECTS_WINDOW" "$runner"
    echo "→ [projects] cloning in tmux window '$_PROJECTS_WINDOW' (session '$target') — setup won't wait."
    if [[ -z "$TMUX" ]]; then
        echo "             watch it:  tmux attach -t $target"
    fi
}

# OS-specific package/config setup for $1 (one resumable step).
run_platform_setup() {
    local distro="$1"
    case "$distro" in
        ubuntu|debian) source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"; setup_ubuntu ;;
        arch)          source "$SCRIPT_DIR/.bin/setup/arch.sh";   setup_arch ;;
        fedora|rhel|centos|rocky|almalinux)
                       source "$SCRIPT_DIR/.bin/setup/fedora.sh"; setup_fedora ;;
        codespace)     source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"; setup_codespace ;;
        darwin)
            source "$SCRIPT_DIR/.bin/setup/mac.sh"
            install_homebrew
            install_brew_bundle
            setup_kanata_service
            setup_mac
            ;;
        termux)        source "$SCRIPT_DIR/.bin/setup/termux.sh"; setup_termux ;;
        *) return 2 ;;
    esac
}

main() {
    local distro=$(detect_distro)

    case "$distro" in
        ubuntu|debian|arch|fedora|rhel|centos|rocky|almalinux|codespace|darwin|termux) ;;
        *) track_failure "distro" "Unsupported distribution: $distro"; print_failure_summary; exit 1 ;;
    esac

    # step <name> <min-profile> <targets> <cmd…> — profile/target filtered,
    # then idempotent + resumable. Records on success; failed steps resume.
    step rust               core wsl,linux,mac,termux install_rust
    step bn                 core all   setup_bn
    step "platform-$distro" core all   run_platform_setup "$distro"

    # tmux is installed by the platform step above; fire the clone into a detached session
    # now so it runs alongside the remaining tool steps and keeps going after setup exits.
    _projects_launch

    if [ "$distro" != "termux" ]; then
        step tmux-plugins core all   install_tmux_plugins
        step zoxide       core all   install_zoxide
        step starship     core all   install_starship
        step pnpm         dev  all   install_pnpm
        step talosctl     dev  all   install_talosctl
        step git-hooks    core all   setup_git_hooks
        step shell-zsh    core all   change_shell_to_zsh
    fi

    # Work-machine tools (agency, etc.) — only when --work is passed.
    if [[ "$SETUP_WORK" == "true" ]]; then
        step work-tools core all install_work_tools
    fi

    # Clean up sudo keepalive
    [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null

    print_failure_summary
}

main
