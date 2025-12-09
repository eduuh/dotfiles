#!/bin/zsh
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/.bin/setup/common.sh"

main() {
    local distro=$(detect_distro)

    # Run GitHub SSH setup script first to ensure we can clone repositories
    echo "Setting up GitHub CLI and SSH keys..."
    "$SCRIPT_DIR/.bin/gh_keys.sh"

    # For macOS, we need to install Homebrew and Git before cloning repos or installing plugins
    if [ "$distro" = "darwin" ]; then
        echo "Detected macOS. Pre-installing Homebrew and Git..."
        source "$SCRIPT_DIR/.bin/setup/mac.sh"
        install_homebrew
        install_brew_packages
    fi

    install_tmux_plugins
    install_starship
    install_rust
    install_pnpm
    install_talosctl
    setup_git_hooks
    change_shell_to_zsh

    case "$distro" in
        ubuntu|debian)
            clone_repos
            source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"
            setup_ubuntu
            ;;
        arch)
            clone_repos
            source "$SCRIPT_DIR/.bin/setup/arch.sh"
            setup_arch
            ;;
        codespace)
            source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"
            setup_codespace
            ;;
        darwin)
            clone_repos
            # mac.sh is already sourced, and packages installed, but we run setup_mac to finish configuration
            setup_mac
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac

    echo "Setup completed successfully!"
}

main
