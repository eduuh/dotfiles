#!/bin/zsh
# Optional Docker CE installation. Ubuntu-only (uses Docker's apt repo).
# Refuses to run inside a GitHub Codespace.

# ${0:A:h}, not ${BASH_SOURCE[0]}: these are zsh scripts and BASH_SOURCE is a bash-ism
# that expands to nothing under zsh, so SCRIPT_DIR silently became the CALLER's cwd —
# sourcing common.sh only worked when you happened to run this from the repo root.
SCRIPT_DIR="${0:A:h}"
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
