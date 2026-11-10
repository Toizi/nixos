hl.on("hyprland.start", function()
	-- applications are generally started by systemd through depending on graphical-session.target
	hl.exec_cmd("systemctl --user start hypr-session.target")
end)

require("hyprland/monitors")
require("hyprland/config")
require("hyprland/binds")
require("hyprland/submaps")
require("hyprland/scratchpads")
require("hyprland/windowrules")
