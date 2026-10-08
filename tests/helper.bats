#!/usr/bin/env bats
# bin/dropkitty against fake kitten/compositor/noctalia binaries; no kitty or shell needed.

setup() {
    ROOT=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
    export XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
    mkdir -p "$XDG_RUNTIME_DIR"
    LOG="$BATS_TEST_TMPDIR/log"; export LOG
    : >"$LOG"
    FAKES="$BATS_TEST_TMPDIR/fakes"; mkdir -p "$FAKES"
    export PATH="$FAKES:$PATH"
    unset NIRI_SOCKET HYPRLAND_INSTANCE_SIGNATURE SWAYSOCK
    export NIRI_SOCKET=fake
    OUT_W=1920 OUT_H=1200; export OUT_W OUT_H

    # kitten: launch creates a live socket named after a real pid; @ calls are logged.
    cat >"$FAKES/kitten" <<'EOF'
#!/usr/bin/env bash
echo "kitten $*" >>"$LOG"
if [ "$1" = quick-access-terminal ]; then
    for a in "$@"; do case $a in kitty_override=listen_on=unix:*) base=${a#kitty_override=listen_on=unix:} ;; esac; done
    sleep 300 & pid=$!
    : >"$base-$pid"
fi
EOF
    cat >"$FAKES/setsid" <<'EOF'
#!/usr/bin/env bash
[ "$1" = -f ] && shift
"$@"
EOF
    cat >"$FAKES/noctalia" <<'EOF'
#!/usr/bin/env bash
echo "noctalia $*" >>"$LOG"
EOF
    cat >"$FAKES/niri" <<'EOF'
#!/usr/bin/env bash
printf '{"name":"eDP-1","logical":{"width":%s,"height":%s}}\n' "$OUT_W" "$OUT_H"
EOF
    cat >"$FAKES/hyprctl" <<'EOF'
#!/usr/bin/env bash
printf '[{"focused":false,"width":1,"height":1,"scale":1,"transform":0},{"focused":true,"width":2400,"height":3840,"scale":2,"transform":1}]\n'
EOF
    cat >"$FAKES/swaymsg" <<'EOF'
#!/usr/bin/env bash
printf '[{"focused":true,"rect":{"width":1280,"height":800}}]\n'
EOF
    chmod +x "$FAKES"/*
    DK="$ROOT/bin/dropkitty"
}

teardown() {
    pkill -f "sleep 300" -P $$ 2>/dev/null || true
    for s in "$XDG_RUNTIME_DIR"/dropkitty/kitty-*; do [ -e "$s" ] && kill "${s##*-}" 2>/dev/null; done
    true
}

# notify() is fire-and-forget; give the background noctalia call a moment to land.
wait_log() { for _ in $(seq 1 30); do grep -q -- "$1" "$LOG" && return 0; sleep 0.05; done; echo "missing in log: $1"; cat "$LOG"; return 1; }
state() { sed -n "s/^$1=//p" "$XDG_RUNTIME_DIR/dropkitty/state"; }

@test "cold toggle launches the kitten with plugin overrides and reports shown" {
    run "$DK" toggle
    [ "$status" -eq 0 ]
    grep -q -- "--instance-group dropkitty" "$LOG"
    grep -q -- "-o focus_policy=on-demand" "$LOG"
    grep -q -- "-o kitty_override=watcher=$ROOT/bin/dropkitty-watcher.py" "$LOG"
    grep -q -- "-o edge=top -o lines=480px" "$LOG"
    [ "$(state visible)" = 1 ]
    wait_log "noctalia msg plugin lowcache/dropkitty:service all shown"
}

@test "warm toggle flips visibility through remote control" {
    "$DK" toggle
    run "$DK" toggle
    [ "$status" -eq 0 ]
    grep -q "resize-os-window --action=toggle-visibility" "$LOG"
    [ "$(state visible)" = 0 ]
    wait_log "all hidden"
}

@test "bar reserves are subtracted on the size axis only" {
    "$DK" _settings reserve_bottom=51 reserve_right=60
    "$DK" show
    grep -q -- "-o lines=459px" "$LOG"   # (1200-51)*40%
    "$DK" full
    grep -q -- "edge=top lines=1149px" "$LOG"
    "$DK" portrait
    grep -q -- "edge=right columns=1860px" "$LOG"  # full: 1920-60
    "$DK" normal
    grep -q -- "edge=right columns=930px" "$LOG"
}

@test "position flips the side for the current orientation" {
    "$DK" show
    "$DK" position
    [ "$(state pos_h)" = bottom ]
    "$DK" orientation
    "$DK" position
    [ "$(state pos_v)" = left ]
    [ "$(state pos_h)" = bottom ]
}

@test "_settings drops unknown keys and invalid values fall back to defaults" {
    "$DK" _settings orientation=sideways evil=1 normal_height=500
    ! grep -q evil "$XDG_RUNTIME_DIR/dropkitty/settings"
    "$DK" show
    grep -q -- "-o edge=top -o lines=480px" "$LOG"
}

@test "_settings re-seeds geometry only when its defaults change" {
    "$DK" show
    "$DK" bottom
    "$DK" _settings opacity=0.5
    [ "$(state pos_h)" = bottom ]
    "$DK" _settings opacity=0.5 orientation=portrait edge_v=left
    [ "$(state orient)" = portrait ]
    [ "$(state pos_v)" = left ]
    [ "$(state pos_h)" = top ]
}

@test "finished command badges only while hidden" {
    "$DK" show
    "$DK" _event cmd 1
    sleep 0.3
    ! grep -q "cmd-finished" "$LOG"
    "$DK" hide
    "$DK" _event cmd 3
    wait_log "all cmd-finished 3"
}

@test "focus loss hides only with hide_on_focus_loss" {
    "$DK" show
    "$DK" _event focus 0
    [ "$(state visible)" = 1 ]
    "$DK" _settings hide_on_focus_loss=yes
    "$DK" _event focus 0
    [ "$(state visible)" = 0 ]
    "$DK" _event focus 1
    [ "$(state visible)" = 1 ]
}

@test "stale sockets are discarded" {
    mkdir -p "$XDG_RUNTIME_DIR/dropkitty"
    : >"$XDG_RUNTIME_DIR/dropkitty/kitty-999999"
    run "$DK" status
    [ "$output" = "alive=0 visible=0" ]
    [ ! -e "$XDG_RUNTIME_DIR/dropkitty/kitty-999999" ]
}

@test "exit event marks it gone" {
    "$DK" show
    "$DK" _event exit
    [ "$(state visible)" = 0 ]
    wait_log "all exited"
}

@test "hyprland output size is logical and rotation-aware" {
    unset NIRI_SOCKET; export HYPRLAND_INSTANCE_SIGNATURE=x
    "$DK" show
    grep -q -- "-o lines=480px" "$LOG"  # 2400x3840 @2x rotated -> 1920x1200; 40% of 1200
}

@test "sway output size comes from the focused rect" {
    unset NIRI_SOCKET; export SWAYSOCK=x
    "$DK" show
    grep -q -- "-o lines=320px" "$LOG"
}

@test "unsupported compositor fails loudly" {
    unset NIRI_SOCKET
    run "$DK" show
    [ "$status" -eq 2 ]
    [[ "$output" == *"unsupported compositor"* ]]
}

@test "hide and status are safe when nothing is running" {
    run "$DK" hide
    [ "$status" -eq 0 ]
    run "$DK" status
    [ "$output" = "alive=0 visible=0" ]
}
