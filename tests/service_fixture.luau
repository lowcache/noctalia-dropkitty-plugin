-- Config the service sees at startup: two reserving bars, one disabled, plus the `order` array.
__config = { hide_on_focus_loss = true, kitty_conf = "~/qa.conf", opacity = 0.75 }
__settings.bar = {
  order = { "bottom", "side", "old" },
  bottom = { position = "bottom", thickness = 51 },
  side = { position = "right", thickness = 60, margin_edge = 4, margin_opposite_edge = 2 },
  old = { position = "top", enabled = false, thickness = 40 },
}
