local g = require("hyprland/globals")

-- Resize submap
local resize_submap = "resize window h/j/k/l"
hl.bind(g.mainMod .. "+ R", hl.dsp.submap(resize_submap))
hl.define_submap(resize_submap, function()
	-- Set repeating binds for resizing the active window.
	hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })

	hl.bind("escape", hl.dsp.submap("reset"))
end)

-- System submap
local system_submap = "System (l)ock, (e)xit, (s)uspend, (h)ibernate, (r)eboot, (p)oweroff"
hl.bind(g.mainMod .. "+ CTRL + L", hl.dsp.submap(system_submap))
hl.define_submap(system_submap, function()
	hl.bind("L", hl.dsp.exec_cmd([[hyprctl dispatch "hl.dsp.submap('reset')"; hyprlock]]))
	hl.bind("E", hl.dsp.exit())
	hl.bind("S", hl.dsp.exec_cmd("systemctl suspend"))
	hl.bind("H", hl.dsp.exec_cmd("systemctl hibernate"))
	hl.bind("R", hl.dsp.exec_cmd("systemctl reboot"))
	hl.bind("P", hl.dsp.exec_cmd("systemctl poweroff"))

	hl.bind("return", hl.dsp.submap("reset"))
	hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Bluetooth submap
local bluetooth_submap = "Bluetooth (o)n, (p)oweroff, (c)onnect"
hl.bind(g.mainMod .. "+ CTRL + B", hl.dsp.submap(bluetooth_submap))
hl.define_submap(bluetooth_submap, function()
	hl.bind(
		"C",
		hl.dsp.exec_cmd([[hyprctl dispatch "hl.dsp.submap('reset')"; ~/.my_scripts/bluetoothctl_headphone_connect]]),
		{ description = "connect" }
	)
	hl.bind("O", hl.dsp.exec_cmd([[hyprctl dispatch "hl.dsp.submap('reset')"; sudo systemctl start bluetooth.service]]))
	hl.bind("P", hl.dsp.exec_cmd([[hyprctl dispatch "hl.dsp.submap('reset')"; sudo systemctl stop bluetooth.service]]))

	hl.bind("return", hl.dsp.submap("reset"))
	hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Screenshot submap
local screenshot_submap = "Screenshot (w)indow, (a)rea, (c)urrent window"
hl.bind(g.mainMod .. "+ CTRL + S", hl.dsp.submap(screenshot_submap))

hl.define_submap(screenshot_submap, function()
	hl.bind(
		"W",
		hl.dsp.exec_cmd([[hyprctl dispatch "hl.dsp.submap('reset')"; ~/.my_scripts/hypr_screenshot select_window]])
	)
	hl.bind(
		"A",
		hl.dsp.exec_cmd([[hyprctl dispatch "hl.dsp.submap('reset')"; ~/.my_scripts/hypr_screenshot select_area]])
	)
	hl.bind(
		"C",
		hl.dsp.exec_cmd([[hyprctl dispatch "hl.dsp.submap('reset')"; ~/.my_scripts/hypr_screenshot active_window]])
	)

	hl.bind("return", hl.dsp.submap("reset"))
	hl.bind("escape", hl.dsp.submap("reset"))
end)
