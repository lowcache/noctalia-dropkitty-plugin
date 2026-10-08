--!nonstrict
-- Noctalia v5 plugin runtime types for `luau-analyze --definitions=` (from claude-companion,
-- plus getSetting/openSettings). plugin.toml stays the contract for which entry gets what.

declare noctalia: {
	tr: (string, table?) -> string,
	readFile: (string) -> string?,
	listDir: ((string) -> {string}?)?,
	expandPath: (string) -> string,
	getenv: (string) -> string?,
	getConfig: (string) -> any,
	isDarkMode: () -> boolean,
	formatTime: (any) -> string,
	notify: (any, any?, any?) -> (),
	notifyError: (any, any?) -> (),
	runAsync: (any, ((any) -> ())?, number?) -> boolean,
	runInTerminal: (string) -> (),
	runStream: (string, (string) -> ()) -> (),
	setUpdateInterval: (number) -> (),
	pluginDir: (() -> string?)?,
	getSetting: ((string) -> any)?,
	openSettings: () -> (),
	nowMs: (() -> number)?,
	json: { decode: (string) -> any, encode: ((any) -> string)? },
	string: { urlEncode: (string) -> string },
	state: {
		get: (string) -> any,
		set: (string, any) -> (),
		watch: (string, (any) -> ()) -> (),
	},
}

declare ui: {
	label: (table) -> any,
	row: (table, table?) -> any,
	column: (table, table?) -> any,
	button: (table) -> any,
	separator: (table) -> any,
	scroll: (table, table?) -> any,
	box: (table, table?) -> any,
	glyph: (table) -> any,
	input: (table) -> any,
}

declare panel: {
	render: (any) -> (),
	setWantsSecondTicks: (boolean) -> (),
}

declare barWidget: {
	setGlyph: (string) -> (),
	setGlyphColor: (string) -> (),
	setTooltip: (string) -> (),
}

declare desktopWidget: {
	render: (any) -> (),
	setNeedsFrameTick: (boolean) -> (),
}

declare launcher: {
	setResults: (table) -> (),
	show: (any?) -> (),
	launch: (any?) -> (),
	ask: (any?) -> (),
	continue: (any?) -> (),
}
