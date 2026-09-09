#!/bin/zsh
# Optional Rust installation. Run when needed.

# ${0:A:h}, not ${BASH_SOURCE[0]}: these are zsh scripts and BASH_SOURCE is a bash-ism
# that expands to nothing under zsh, so SCRIPT_DIR silently became the CALLER's cwd —
# sourcing common.sh only worked when you happened to run this from the repo root.
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/.bin/setup/common.sh"

install_rust
