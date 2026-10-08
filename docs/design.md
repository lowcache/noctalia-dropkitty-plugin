# dropkitty v1 design (2026-10-08)

## Scope

v1 has these parts:
- a standalone helper (ported from a working niri `quake.sh`)
- a bar widget
- settings
- bar-aware sizing
- a finished-command badge
- support for niri, Hyprland and sway

Deferred to later releases:
- named profiles
- follow-focus across monitors (kitty can't move a layer-shell surface between outputs, so it would have to respawn and lose the session)
- tmux/zellij support
- a Ghostty backend (`ghostty +toggle-quick-terminal` only arrives in Ghostty 1.4.0)

## Architecture

```
compositor keybind ─► bin/dropkitty ─► kitten @ (unix socket in $XDG_RUNTIME_DIR/dropkitty)
bar widget click  ─►       │  ▲
                           │  └─ _settings  ◄── service.luau (onConfigChanged, bar poll)
                           └─ noctalia msg plugin lowcache/dropkitty:service all <event>
kitty watcher (bin/dropkitty-watcher.py) ─► dropkitty _event … ─► (same notify path)
service.luau ─► noctalia.state["dropkitty"] ─► widget.luau
```

- **The helper is the only thing that touches kitty.** Keybinds never go through Noctalia's IPC, so the terminal keeps working while the shell reloads. The helper notifies the plugin in the background with a 1 s timeout and ignores failures.
- **The helper is the only writer of its files.** The service passes settings in through `_settings`, and the helper validates every value and falls back to defaults for anything invalid. A `flock` serializes keybind repeats, clicks and watcher events. The lock file descriptor is closed before kitty and `noctalia` are spawned, because otherwise they inherit it and hold the lock.
- **Visibility is tracked by the helper.** `kitten @ ls` doesn't report whether an OS window is visible, so the helper records it. The watcher's `on_focus_change` corrects it: gaining focus means visible, and losing focus means hidden only when `hide_on_focus_loss` is on.
- **The badge comes from the kitty watcher, not shell snippets.** It uses `on_cmd_startstop` with `exit_status`, fed by kitty's shell integration, so there's nothing to set up. This replaced the planned bash/zsh/fish snippets.
- **Bars:** kitty's quick-access panel uses `--exclusive-zone=0 --override-exclusive-zone`, so the compositor already keeps it clear of Noctalia bars (verified on niri). The helper only subtracts reserved space on the size axis. The service works that space out from `getSetting("bar")` (thickness plus edge margins), and checks every 10 s because bar edits don't trigger `onConfigChanged`.

## Verified

- Offline checks (`make check` in `nix develop`): shellcheck, luau-analyze, 14 bats tests for the helper with fake kitty/compositor/noctalia binaries, and Luau specs for the widget (15 checks) and service (22 checks).
- Live on niri with kitty 0.49.1 and Noctalia 5.1.0:
  - launch and toggle
  - stays clear of the bars' reserved space
  - watcher events: `cmd-finished` with the exit code, and `exited`
  - the service's settings sync, including bar reserves read from the real config
  - IPC dispatch to the service
- Found live: if a command finishes within about 7 s of hiding the panel, kitty delays the watcher callback until about 7 s after the hide.
