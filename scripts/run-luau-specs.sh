#!/usr/bin/env bash
# Runs each entry headless: prelude (host stubs) + fixtures + entry + spec, concatenated.
set -euo pipefail
cd "${1:-$(dirname "$0")/..}"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
rc=0
run() { # name files...
    local name=$1; shift
    echo "-- $name"
    cat "$@" >"$tmp/$name.luau"
    luau "$tmp/$name.luau" || rc=1
}
run widget  tests/prelude.luau widget.luau tests/widget_spec.luau
run service tests/prelude.luau tests/service_fixture.luau service.luau tests/service_spec.luau
exit $rc
