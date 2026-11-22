import importlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import time

import bpy


def configure_client(path, server):
    path = path.expanduser().resolve()
    config = json.loads(path.read_text()) if path.exists() else {}
    servers = config.setdefault("mcpServers", {})
    if servers.get("blender") == server:
        return
    servers["blender"] = server
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        shutil.copy2(path, str(path) + ".bak-" + str(time.time_ns()))
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
    try:
        with os.fdopen(fd, "w") as handle:
            json.dump(config, handle, indent=2)
            handle.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print("Configured Blender MCP:", path)


def main():
    addon_zip, command, version = sys.argv[sys.argv.index("--") + 1:]
    if bpy.app.version < (5, 1, 0):
        raise RuntimeError("The official Blender MCP add-on requires Blender 5.1 or newer")

    preferences = bpy.context.preferences
    preference_file = Path(bpy.utils.user_resource("CONFIG")) / "userpref.blend"
    if preference_file.exists():
        shutil.copy2(preference_file, str(preference_file) + ".bak-" + str(time.time_ns()))
    preferences.system.use_online_access = True
    module = "bl_ext.user_default.mcp"
    installed = preferences.addons.get(module)
    manifest = Path(bpy.utils.user_resource("EXTENSIONS")) / "user_default/mcp/blender_manifest.toml"
    import tomllib
    installed_version = tomllib.loads(manifest.read_text())["version"] if manifest.exists() else None
    if installed_version != version:
        result = bpy.ops.extensions.package_install_files(
            filepath=addon_zip, repo="user_default", enable_on_install=True, overwrite=True,
        )
        if result != {"FINISHED"}:
            raise RuntimeError("Blender MCP extension installation failed")
    elif installed is None:
        if bpy.ops.preferences.addon_enable(module=module) != {"FINISHED"}:
            raise RuntimeError("Blender MCP extension could not be enabled")
    addon = preferences.addons[module].preferences
    addon.host = "127.0.0.1"
    addon.port = 9876
    addon.use_autostart = True
    if bpy.ops.wm.save_userpref() != {"FINISHED"}:
        raise RuntimeError("Blender preferences could not be saved")
    print("Blender MCP add-on ready:", importlib.import_module(module).__package__)

    home = Path.home()
    server = {"command": command, "args": [], "env": {"BLENDER_MCP_HOST": "127.0.0.1", "BLENDER_MCP_PORT": "9876"}}
    configure_client(
        Path(os.environ.get("COPILOT_HOME", str(home / ".copilot"))) / "mcp-config.json",
        {"type": "stdio", "tools": ["*"], **server},
    )
    configure_client(home / ".claude.json", {"type": "stdio", **server})
    desktop = (
        home / "Library/Application Support/Claude"
        if sys.platform == "darwin"
        else Path(os.environ.get("XDG_CONFIG_HOME", str(home / ".config"))) / "Claude"
    )
    configure_client(desktop / "claude_desktop_config.json", server)


if __name__ == "__main__":
    main()
