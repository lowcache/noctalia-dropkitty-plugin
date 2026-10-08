-- dropkitty bar widget: a view of noctalia.state["dropkitty"] (published by service.luau).
-- Left click toggles the drop-down through the helper, right click opens settings.

local KEY = "dropkitty"
local GLYPH = "terminal-2"

local function tr(key, args)
  return noctalia.tr(key, args)
end

local function helper()
  local dir = noctalia.pluginDir and noctalia.pluginDir()
  return dir and (dir .. "/bin/dropkitty") or nil
end

local function render(s)
  s = type(s) == "table" and s or {}
  barWidget.setGlyph(GLYPH)
  if s.error then
    barWidget.setGlyphColor("error")
    barWidget.setTooltip(tr("widget.error", { message = tostring(s.error) }))
  elseif s.badge ~= nil then
    barWidget.setGlyphColor(s.badge == 0 and "tertiary" or "error")
    barWidget.setTooltip(tr("widget.finished", { code = tostring(s.badge) }))
  elseif s.open then
    barWidget.setGlyphColor("primary")
    barWidget.setTooltip(tr("widget.open"))
  elseif s.alive then
    barWidget.setGlyphColor("on_surface")
    barWidget.setTooltip(tr("widget.hidden"))
  else
    barWidget.setGlyphColor("on_surface_variant")
    barWidget.setTooltip(tr("widget.stopped"))
  end
end

function onClick()
  local bin = helper()
  if not bin or not noctalia.runAsync({ bin, "toggle" }) then
    noctalia.notifyError(tr("widget.title"), tr("widget.launch_failed"))
  end
end

function onRightClick()
  noctalia.openSettings()
end

noctalia.state.watch(KEY, render)
render(noctalia.state.get(KEY))
