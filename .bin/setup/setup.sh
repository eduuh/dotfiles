#!/bin/zsh
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/common.sh"

main() {
    local distro=$(detect_distro)

    clone_repos
    install_tmux_plugins
    install_starship
    install_rust
    install_pnpm
    change_shell_to_zsh

    case "$distro" in
        ubuntu|debian)
            source "$SCRIPT_DIR/ubuntu.sh"
            setup_ubuntu
            ;;
        arch)
            source "$SCRIPT_DIR/arch.sh"
            setup_arch
            ;;
        codespace)
            source "$SCRIPT_DIR/ubuntu.sh"
            setup_codespace
            ;;
        darwin)
            source "$SCRIPT_DIR/mac.sh"
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
