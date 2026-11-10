local g = require("hyprland/globals")

hl.bind(g.mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(g.mainMod .. " + RETURN", hl.dsp.exec_cmd(g.terminal))
hl.bind(
	g.mainMod .. " + O",
	hl.dsp.exec_cmd("wofi --insensitive --allow-images --allow-markup --show=drun --location=top_left")
)
hl.bind(g.mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(g.mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(g.mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(g.mainMod .. " + I", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(g.mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(g.mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move focus with mainMod + arrow keys/vim directions
hl.bind(g.mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(g.mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(g.mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(g.mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(g.mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(g.mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(g.mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(g.mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move windows with g.mainMod + shift + arrow keys/vim directions
hl.bind(g.mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(g.mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(g.mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(g.mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

hl.bind(g.mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(g.mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(g.mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(g.mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Scroll through existing workspaces with g.mainMod + scroll
-- hl.bind(g.mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(g.mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with g.mainMod + LMB/RMB and dragging
hl.bind(g.mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(g.mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
