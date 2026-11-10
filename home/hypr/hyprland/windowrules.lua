
hl.window_rule({
	name = "app-ws10",
	match = {
		class = "^(firefox)$",
	},
	workspace = 10,
})
hl.window_rule({
	name = "app-ws9",
	match = {
		class = "^(Signal|signal|thunderbird)$",
	},
	workspace = 9,
})
hl.window_rule({
	name = "app-ws5",
	match = {
		class = "^(Spotify)$",
	},
	workspace = 5,
})

hl.window_rule({
	name = "apps-floating",
	match = {
		title = "^(Battle.net)$",
	},
	float = true,
})
