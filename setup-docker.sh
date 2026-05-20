#!/bin/zsh
# Optional Docker CE installation. Ubuntu-only (uses Docker's apt repo).
# Refuses to run inside a GitHub Codespace.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.bin/setup/common.sh"

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot detect distro (no /etc/os-release). This script is Ubuntu-only." >&2
    exit 1
fi
. /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    echo "Unsupported distro: $ID. This script is Ubuntu-only." >&2
    exit 1
fi

source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"

# Cache sudo upfront
sudo -v || { echo "Need sudo to install Docker." >&2; exit 1; }

install_docker

print_failure_summary
