#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/.bin/setup/common.sh"

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

main() {
    local distro=$(detect_distro)

    # GitHub auth + SSH keys are handled in prep (Phase 1), so cloning works here.
    # Bootstrap cloned dotfiles WITHOUT submodules (private, pre-auth); now that
    # prep established auth, populate them (bn, tmux-workflow).
    echo "Updating dotfiles submodules..."
    if ! git -C "$SCRIPT_DIR" submodule update --init --recursive; then
        track_failure "submodules" "Failed to init/update dotfiles submodules"
    fi

    # For macOS, install Homebrew and all packages via Brewfile
    if [ "$distro" = "darwin" ]; then
        echo "Detected macOS. Installing Homebrew and packages..."
        source "$SCRIPT_DIR/.bin/setup/mac.sh"
        install_homebrew
        install_brew_bundle
        setup_kanata_service
    fi

    case "$distro" in
        ubuntu|debian)
            source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"
            setup_ubuntu
            ;;
        arch)
            source "$SCRIPT_DIR/.bin/setup/arch.sh"
            setup_arch
            ;;
        codespace)
            source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"
            setup_codespace
            ;;
        darwin)
            # mac.sh is already sourced; finish configuration
            setup_mac
            ;;
        termux)
            source "$SCRIPT_DIR/.bin/setup/termux.sh"
            setup_termux
            ;;
        *)
            track_failure "distro" "Unsupported distribution: $distro"
            print_failure_summary
            exit 1
            ;;
    esac

    if [ "$distro" != "termux" ]; then
        install_tmux_plugins
        install_zoxide
        install_starship
        install_pnpm
        install_talosctl
        setup_git_hooks
        change_shell_to_zsh
    fi

    echo ""
    echo "To clone project repos:  ./setup-projects.sh"
    echo "To install Rust:         ./setup-rust.sh"

    # Clean up sudo keepalive
    [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null

    # Print summary of any failures
    print_failure_summary
}

main
