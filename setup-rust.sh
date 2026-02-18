#!/bin/zsh
# Optional Rust installation. Run when needed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.bin/setup/common.sh"

install_rust
