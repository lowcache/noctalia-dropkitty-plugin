# dropkitty

A Quake-style drop-down terminal for Noctalia, built on kitty's `quick-access-terminal` kitten. One key drops it down and hides it again with your shell session intact. A bar widget shows whether it's open and lights up when a command finishes while it's hidden.

The terminal is a layer-shell panel that kitty draws itself, so it works the same on niri, Hyprland and sway. It doesn't depend on compositor scratchpads, which niri doesn't have.

## Plugin

- **Helper** (`bin/dropkitty`): shows, hides, moves and resizes the terminal. Your compositor keybinds call it directly, so the terminal keeps working while Noctalia is reloading or not running.
- **Bar widget**: click to toggle, right-click for settings. The colour shows the state: muted when stopped, normal when hidden, primary when open. After a command finishes while hidden it turns tertiary (exit 0) or error (non-zero) until you show the terminal again.
- **Service**: copies your settings to the helper and works out how much room your Noctalia bars take, so a full-size terminal never runs under a bar.

## Requirements

- kitty 0.42 or newer (`kitten quick-access-terminal`)
- niri, Hyprland or sway
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

| Setting | Default | Notes |
|---|---|---|
| Orientation, Landscape edge, Portrait edge, Size | landscape, top, right, normal | Where a freshly started terminal opens |
| Normal height / width (%) | 40 / 50 | Percent of the usable screen, after bars |
| Fit around bars | on | Subtract the space Noctalia bars reserve |
| Opacity | 0.9 | Applies on next launch |
| Keyboard focus | On demand | On demand keeps compositor keybinds working while the terminal is open. Applies on next launch |
| Hide on focus loss | off | Applies on next launch |
| Kitten config file | (none) | Replaces `~/.config/kitty/quick-access-terminal.conf` |

Everything else (font, colours, shell) comes from your kitty and kitten config. The plugin's settings take precedence over the same options there.

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
