-- Stubs the noctalia host API so widget.luau / service.luau run headless.
-- Concatenated before the entry under test, then the spec (see scripts/run-luau-specs.sh).

__glyph, __color, __tip = nil, nil, nil
__runs = {}
__config = {}
__settings = {}
__state = {}
__watch = {}
__interval = nil
__opened_settings = false

barWidget = {
  setGlyph = function(g) __glyph = g end,
  setGlyphColor = function(c) __color = c end,
  setTooltip = function(t) __tip = t end,
}

noctalia = {
  tr = function(key, args)
    local s = key
    for k, v in pairs(args or {}) do
      s = s .. " " .. k .. "=" .. tostring(v)
    end
    return s
  end,
  pluginDir = function() return "/plug" end,
  getConfig = function(k) return __config[k] end,
  getSetting = function(p) return __settings[p] end,
  expandPath = function(p) return (p:gsub("^~", "/home/u")) end,
  runAsync = function(cmd, cb)
    table.insert(__runs, { cmd = cmd, cb = cb })
    return true
  end,
  setUpdateInterval = function(ms) __interval = ms end,
  openSettings = function() __opened_settings = true end,
  notifyError = function() end,
  state = {
    get = function(k) return __state[k] end,
    set = function(k, v)
      __state[k] = v
      if __watch[k] then __watch[k](v) end
    end,
    watch = function(k, cb) __watch[k] = cb end,
  },
}

local failures = 0
function expect(label, got, want)
  if got ~= want then
    failures = failures + 1
    print(string.format("FAIL %s\n  got : %s\n  want: %s", label, tostring(got), tostring(want)))
  else
    print("ok   " .. label)
  end
end
function finish()
  if failures > 0 then
    error(failures .. " failure(s)")
  end
end
function argv_has(argv, item)
  for _, a in ipairs(argv) do
    if a == item then return true end
  end
  return false
end
