#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/.bin/setup/common.sh"

# Ask for sudo upfront and keep the session alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!

main() {
    local distro=$(detect_distro)

    # Run GitHub SSH setup script first to ensure we can clone repositories
    echo "Setting up GitHub CLI and SSH keys..."
    if ! "$SCRIPT_DIR/.bin/gh_keys.sh"; then
        track_failure "github" "Failed to setup GitHub CLI/SSH keys"
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
        *)
            track_failure "distro" "Unsupported distribution: $distro"
            print_failure_summary
            exit 1
            ;;
    esac

    install_tmux_plugins
    install_zoxide
    install_starship
    install_pnpm
    install_talosctl
    setup_git_hooks
    change_shell_to_zsh

    echo ""
    echo "To clone project repos:  ./setup-projects.sh"
    echo "To install Rust:         ./setup-rust.sh"

    # Clean up sudo keepalive
    kill "$SUDO_PID" 2>/dev/null

    # Print summary of any failures
    print_failure_summary
}

main
