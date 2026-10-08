-- service.luau: settings mirroring, bar reserves, IPC -> published state.
-- tests/service_fixture.luau seeds __config/__settings before the entry runs.

local function last_settings_argv()
  for i = #__runs, 1, -1 do
    if __runs[i].cmd[2] == "_settings" then return __runs[i].cmd end
  end
  return {}
end

local argv = last_settings_argv()
expect("startup syncs settings", argv[1], "/plug/bin/dropkitty")
expect("bottom bar reserved", argv_has(argv, "reserve_bottom=51"), true)
expect("side bar reserved with margins", argv_has(argv, "reserve_right=66"), true)
expect("disabled bar ignored", argv_has(argv, "reserve_top=0"), true)
expect("order array ignored", argv_has(argv, "reserve_left=0"), true)
expect("bool maps to yes/no", argv_has(argv, "hide_on_focus_loss=yes"), true)
expect("kitty_conf expanded", argv_has(argv, "kitty_conf=/home/u/qa.conf"), true)
expect("opacity formatted", argv_has(argv, "opacity=0.75"), true)
expect("bar poll armed", __interval, 10000)

-- status seeds state
local status
for _, r in ipairs(__runs) do
  if r.cmd[2] == "status" then status = r end
end
status.cb({ exitCode = 0, stdout = "alive=1 visible=1\n", stderr = "" })
expect("status alive", __state.dropkitty.alive, true)
expect("status open", __state.dropkitty.open, true)

onIpc("hidden", "")
expect("hidden", __state.dropkitty.open, false)
onIpc("cmd-finished", "3")
expect("badge set", __state.dropkitty.badge, 3)
onIpc("shown", "")
expect("show clears badge", __state.dropkitty.badge, nil)
onIpc("exited", "")
expect("exited not alive", __state.dropkitty.alive, false)
onIpc("bogus", "")
expect("unknown event ignored", __state.dropkitty.alive, false)

-- helper failure surfaces as error, success clears it
local sync = __runs[1] -- the startup _settings call
sync.cb({ exitCode = 2, stdout = "", stderr = "dropkitty: unsupported compositor\n" })
expect("helper error published", __state.dropkitty.error, "dropkitty: unsupported compositor")
sync.cb({ exitCode = 0, stdout = "", stderr = "" })
expect("error cleared", __state.dropkitty.error, nil)

-- bar edits resync only when reserves change
local n = #__runs
update()
expect("unchanged reserves: no resync", #__runs, n)
__settings.bar.bottom.thickness = 60
update()
expect("changed reserves: resync", #__runs, n + 1)
expect("new reserve sent", argv_has(last_settings_argv(), "reserve_bottom=60"), true)

-- bar_aware off zeroes reserves
__config.bar_aware = false
onConfigChanged()
expect("bar_aware off", argv_has(last_settings_argv(), "reserve_bottom=0"), true)

finish()
