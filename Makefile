# Offline gates. Inside `nix develop` the tools are on PATH; the live shell confirms behaviour.
.PHONY: check lint helper luau

check: lint helper luau

lint:
	shellcheck bin/dropkitty
	luau-analyze --definitions=noctalia.d.luau service.luau widget.luau
	python3 -m py_compile bin/dropkitty-watcher.py && rm -rf bin/__pycache__

helper:
	bats tests/helper.bats

luau:
	scripts/run-luau-specs.sh
