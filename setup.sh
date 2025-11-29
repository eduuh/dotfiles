#!/bin/zsh
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/.bin/setup/common.sh"

main() {
    local distro=$(detect_distro)

    install_tmux_plugins
    install_starship
    install_rust
    install_pnpm
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
            source "$SCRIPT_DIR/.bin/setup/mac.sh"
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
