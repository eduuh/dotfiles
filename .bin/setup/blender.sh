#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../../versions.lock"

BLENDER_BIN=$(command -v blender || true)
if [[ -z "$BLENDER_BIN" && -x /Applications/Blender.app/Contents/MacOS/Blender ]]; then
    BLENDER_BIN=/Applications/Blender.app/Contents/MacOS/Blender
fi
if [[ -z "$BLENDER_BIN" ]] || ! command -v uv >/dev/null; then
    echo "Blender and uv are required; re-run platform package setup." >&2
    exit 1
fi

install_dir="$HOME/.local/share/blender-mcp/$BLENDER_MCP_VERSION"
mkdir -p "$install_dir"
base_url="https://projects.blender.org/lab/blender_mcp/releases/download/v$BLENDER_MCP_VERSION"

download() {
    local name="$1" checksum="$2" actual
    if [[ ! -f "$install_dir/$name" ]]; then
        curl --proto '=https' --tlsv1.2 -fsSL "$base_url/$name" -o "$install_dir/$name.download"
        mv "$install_dir/$name.download" "$install_dir/$name"
    fi
    if command -v sha256sum >/dev/null; then
        actual=$(sha256sum "$install_dir/$name")
    else
        actual=$(shasum -a 256 "$install_dir/$name")
    fi
    if [[ "${actual%% *}" != "$checksum" ]]; then
        echo "Checksum mismatch: $install_dir/$name" >&2
        exit 1
    fi
}

download "blender-$BLENDER_MCP_VERSION.mcpb" "$BLENDER_MCP_BUNDLE_SHA256"
download "mcp-$BLENDER_MCP_VERSION.zip" "$BLENDER_MCP_ADDON_SHA256"
unzip -qo "$install_dir/blender-$BLENDER_MCP_VERSION.mcpb" -d "$install_dir/server"
uv sync --directory "$install_dir/server" --no-dev

"$BLENDER_BIN" --background --online-mode --python-exit-code 1 \
    --python "$SCRIPT_DIR/blender.py" -- \
    "$install_dir/mcp-$BLENDER_MCP_VERSION.zip" \
    "$install_dir/server/.venv/bin/blender-mcp" "$BLENDER_MCP_VERSION"
