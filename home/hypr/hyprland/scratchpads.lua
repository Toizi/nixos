local g = require("hyprland/globals")

local function sh_quote(s)
	return "'" .. tostring(s):gsub("'", [['"'"']]) .. "'"
end

local scratchpads = {
	{
		name = "llm_chat",
		key = "U",
		match = "chrome-chat.guggma.net__-Default",
		command = [[chromium --app=https://chat.guggma.net]],
	},
	{
		name = "music",
		key = "M",
		match = "Spotify",
		command = [[spotify]],
	},
	{
		name = "terminal",
		key = "RETURN",
		match = "scratch-terminal",
		command = [[alacritty --class scratch-terminal]],
	},
	{
		name = "passwords",
		key = "P",
		match = "org.keepassxc.KeePassXC",
		command = [[keepassxc]],
	},
	{
		name = "audio_control",
		key = "A",
		match = "org.pulseaudio.pavucontrol",
		command = [[pavucontrol]],
	},
}

for _, scratchpad in ipairs(scratchpads) do
	local cmd = table.concat({
		"~/.my_scripts/launch-or-focus-in-special",
		sh_quote(scratchpad.name),
		sh_quote(scratchpad.match),
		scratchpad.command,
	}, " ")

	hl.bind(g.mainMod .. " + SHIFT + " .. scratchpad.key, hl.dsp.exec_cmd(cmd))

	hl.workspace_rule({
		workspace = "special:" .. scratchpad.name,
		gaps_out = 80,
		gaps_in = 12,
		border_size = 3,
	})
end
