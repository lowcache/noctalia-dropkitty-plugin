-- widget.luau: state -> glyph colour/tooltip, clicks -> helper/settings.

expect("initial glyph", __glyph, "terminal-2")
expect("not running is muted", __color, "on_surface_variant")
expect("not running tooltip", __tip, "widget.stopped")

noctalia.state.set("dropkitty", { alive = true, open = true })
expect("open is primary", __color, "primary")

noctalia.state.set("dropkitty", { alive = true, open = false })
expect("hidden is default", __color, "on_surface")
expect("hidden tooltip", __tip, "widget.hidden")

noctalia.state.set("dropkitty", { alive = true, open = false, badge = 0 })
expect("success badge", __color, "tertiary")
expect("badge tooltip carries code", __tip, "widget.finished code=0")

noctalia.state.set("dropkitty", { alive = true, open = false, badge = 2 })
expect("failure badge", __color, "error")

noctalia.state.set("dropkitty", { alive = false, error = "boom" })
expect("error wins", __color, "error")
expect("error tooltip", __tip, "widget.error message=boom")

onClick()
local run = __runs[#__runs]
expect("click runs helper argv", run.cmd[1], "/plug/bin/dropkitty")
expect("click toggles", run.cmd[2], "toggle")
expect("click outlives a cold launch", run.timeout ~= nil and run.timeout >= 10000, true)
run.cb({ exitCode = 0, stdout = "", stderr = "" })
expect("success is silent", #__errors, 0)
run.cb({ exitCode = 2, stdout = "", stderr = "dropkitty: kitten not found (install kitty >= 0.42)\n" })
expect("failure is reported", #__errors, 1)
expect("failure shows helper stderr", __errors[1].body, "dropkitty: kitten not found (install kitty >= 0.42)")
run.cb({ exitCode = -1, timedOut = true, stdout = "", stderr = "" })
expect("timeout is reported", __errors[2] and __errors[2].body, "widget.launch_failed")

onRightClick()
expect("right click opens settings", __opened_settings, true)

finish()
