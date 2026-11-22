-- Personal overrides run last on every reload.
-- Use hl.config(...) for settings and o.rebind(...) to replace default shortcuts.
o.window("^Surfshark$", { workspace = "5 silent" })
o.window("^[Ss]potify$", { workspace = "4 silent" })
o.window("^(org\\.mozilla\\.)?[Tt]hunderbird$", { workspace = "4 silent" })
o.window("^(org\\.kde\\.kdenlive|kdenlive)$", { workspace = "2 silent" })
o.window("^(com\\.obsproject\\.Studio|obs)$", { workspace = "2 silent" })
o.window("^[Bb]lender$", { workspace = "2 silent" })

o.rebind("SUPER + SPACE", "Apps", "omarchy-shell omarchy.dock apps")
o.rebind("SUPER + N", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.rebind("SUPER + E", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.rebind("SUPER + U", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.rebind("SUPER + I", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.rebind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "m+1" }))
o.rebind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "m-1" }))
