#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/.bin/setup/common.sh"

# --- flags: `--force` re-runs every step; `reset` clears recorded step state ---
for arg in "$@"; do
    case "$arg" in
        --force) SETUP_FORCE=true ;;
        reset)   reset_steps; exit 0 ;;
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

# Populate dotfiles submodules (bn, tmux-workflow). Bootstrap skipped them
# pre-auth; prep has since established GitHub auth.
_init_submodules() {
    git -C "$SCRIPT_DIR" submodule update --init --recursive
}

# OS-specific package/config setup for $1 (one resumable step).
run_platform_setup() {
    local distro="$1"
    case "$distro" in
        ubuntu|debian) source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"; setup_ubuntu ;;
        arch)          source "$SCRIPT_DIR/.bin/setup/arch.sh";   setup_arch ;;
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
        ubuntu|debian|arch|codespace|darwin|termux) ;;
        *) track_failure "distro" "Unsupported distribution: $distro"; print_failure_summary; exit 1 ;;
    esac

    # Each step records on success → re-runs skip it, a failed run resumes here.
    run_step submodules         _init_submodules
    run_step "platform-$distro" run_platform_setup "$distro"

    if [ "$distro" != "termux" ]; then
        run_step tmux-plugins install_tmux_plugins
        run_step zoxide       install_zoxide
        run_step starship     install_starship
        run_step pnpm         install_pnpm
        run_step talosctl     install_talosctl
        run_step git-hooks    setup_git_hooks
        run_step shell-zsh    change_shell_to_zsh
    fi

    echo ""
    echo "To clone project repos:  ./setup-projects.sh"
    echo "To install Rust:         ./setup-rust.sh"

    # Clean up sudo keepalive
    [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null

    print_failure_summary
}

main
