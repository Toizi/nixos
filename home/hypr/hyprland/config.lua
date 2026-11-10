hl.config({
	input = {
		kb_layout = "us,us",
		kb_variant = ",intl",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		repeat_delay = 200,
		repeat_rate = 30,
		accel_profile = "flat",
		sensitivity = -0.2, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = true,
		},
	},

	general = {
		gaps_in = 0,
		gaps_out = -10,
		layout = "master",

		border_size = 4,
		col = {
			active_border = "rgba(89b4faff)",
			inactive_border = "rgba(11111b66)",
		},
	},

	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		key_press_enables_dpms = true,
	},

	animations = {
		enabled = false,
	},

	dwindle = {
		preserve_split = true,
	},

	master = {
		special_scale_factor = 0.4,
		mfact = 0.5,
	},
})


