dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

require("default.hypr.omarchy")
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

require("default.hypr.toggles")

-- Personal settings win over Omarchy defaults, theme and saved toggles.
require("hypr.overrides")
