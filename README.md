# dropkitty

A Quake-style drop-down terminal for Noctalia, built on kitty's `quick-access-terminal` kitten. One key drops it down and hides it again with your shell session intact. A bar widget shows whether it's open and lights up when a command finishes while it's hidden.

The terminal is a layer-shell panel that kitty draws itself, so it works the same on niri, Hyprland and sway. It doesn't depend on compositor scratchpads, which niri doesn't have.

## Plugin

| Field | Value |
| --- | --- |
| ID | `lowcache/dropkitty` |
| Entries | Bar widget: `toggle`; service: `service` |

- **Helper** (`bin/dropkitty`): shows, hides, moves and resizes the terminal. Your compositor keybinds call it directly, so the terminal keeps working while Noctalia is reloading or not running.
- **Bar widget** (`toggle`): click to toggle, right-click for settings. The colour shows the state: muted when stopped, normal when hidden, primary when open. After a command finishes while hidden it turns tertiary (exit 0) or error (non-zero) until you show the terminal again.
- **Service** (`service`): copies your settings to the helper and works out how much room your Noctalia bars take, so a full-size terminal never runs under a bar.

## Requirements

- `kitty` 0.42 or newer (`kitten quick-access-terminal`)
- niri, Hyprland or sway. The helper asks `niri`, `hyprctl` or `swaymsg` for the focused output's size.
- `jq`, `flock`, `setsid`, `timeout`
- kitty shell integration, for the finished-command badge. It's on by default for bash, zsh and fish.

## Install

Install from the Noctalia plugin catalog, add the **dropkitty** widget to a bar, then bind a key to the helper. Linking the helper onto your `PATH` keeps the bindings short:

```sh
ln -s ~/.local/state/noctalia/plugins/materialized/community/dropkitty/bin/dropkitty ~/.local/bin/dropkitty
```

**niri** (`config.kdl`):
```kdl
Mod+Return       { spawn "dropkitty" "toggle"; }
Mod+Shift+Return { spawn "dropkitty" "position"; }
Mod+Alt+Return   { spawn "dropkitty" "size"; }
Mod+Ctrl+Return  { spawn "dropkitty" "orientation"; }
```

**Hyprland**:
```ini
bind = SUPER, Return, exec, dropkitty toggle
bind = SUPER SHIFT, Return, exec, dropkitty position
```

**sway**:
```
bindsym $mod+Return exec dropkitty toggle
bindsym $mod+Shift+Return exec dropkitty position
```

## Usage

| Command | Does |
|---|---|
| `toggle` | Show or hide; starts the terminal if it isn't running |
| `show`, `hide` | Explicit show and hide |
| `position` | Landscape: top ↔ bottom. Portrait: left ↔ right |
| `size` | Normal ↔ full |
| `orientation` | Landscape (full width, drops from top or bottom) ↔ portrait (full height, slides from the side) |
| `top`, `bottom`, `left`, `right`, `landscape`, `portrait`, `normal`, `full` | Set one directly |
| `restart` | Restart kitty to apply launch-time settings (this ends the shell session) |
| `status` | Prints `alive=0/1 visible=0/1` |

Live changes from these commands last until kitty restarts or you change the matching setting.

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `orientation` | `select` | `landscape` | Where a freshly started terminal opens. Landscape drops a full-width terminal from the top or bottom; portrait slides a full-height one from the side |
| `edge_h` | `select` | `top` | Edge for landscape: `top` or `bottom` |
| `edge_v` | `select` | `right` | Edge for portrait: `left` or `right` |
| `size` | `select` | `normal` | `normal` uses the percentages below; `full` fills the usable screen along the drop direction |
| `normal_height` | `int` | `40` | Normal landscape height, in percent of the usable screen height (10–100) |
| `normal_width` | `int` | `50` | Normal portrait width, in percent of the usable screen width (10–100) |
| `bar_aware` | `bool` | `true` | Subtract the space Noctalia bars reserve before sizing |
| `opacity` | `double` | `0.9` | Background opacity (0.1–1.0). Applies on next launch |
| `focus_policy` | `select` | `on-demand` | `on-demand` keeps compositor keybinds working while the terminal is open; `exclusive` grabs the keyboard. Applies on next launch |
| `hide_on_focus_loss` | `bool` | `false` | Hide when you click elsewhere. Applies on next launch |
| `kitty_conf` | `file` | (none) | Kitten config used instead of `~/.config/kitty/quick-access-terminal.conf`. Applies on next launch |

Everything else (font, colours, shell) comes from your kitty and kitten config. The plugin's settings take precedence over the same options there.

## IPC

The helper reports state changes to the service; you don't need to send these yourself, but they're listed because the service accepts them:

```sh
noctalia msg plugin lowcache/dropkitty:service all shown
noctalia msg plugin lowcache/dropkitty:service all hidden
noctalia msg plugin lowcache/dropkitty:service all exited
noctalia msg plugin lowcache/dropkitty:service all cmd-finished <exit-code>
```

To control the terminal itself, call the helper (see Usage).

## Notes

### What it touches

- `$XDG_RUNTIME_DIR/dropkitty/`: settings, state, lock and kitty's remote-control socket. Remote control is limited to that socket (`allow_remote_control=socket-only`).
- Runs its own kitty instance group (`dropkitty`), separate from your other kitty windows and any other quick-access terminal.

### Known limits

- **Badge delay right after hiding.** If a command finishes within about 7 seconds of hiding the terminal, kitty delivers the event late, so the badge appears roughly 7 seconds after the hide. Later commands badge immediately.
- **No badge inside tmux or zellij.** kitty can't see commands run inside a multiplexer.
- **One monitor at a time.** The terminal opens on the focused output. Moving it to another monitor needs `restart`, which ends the session.
- **Bar sizing is approximate.** It doesn't account for per-monitor bar layouts or the shadow bleed adjustment, so it can leave a few pixels too much room.
- Opacity, focus policy and hide-on-focus-loss only apply when kitty starts.

## Support

Issues: <https://github.com/lowcache/noctalia-dropkitty-plugin/issues>

## License

MIT
