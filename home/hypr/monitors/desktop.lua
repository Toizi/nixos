local monitorMain = "desc:ViewSonic Corporation VX2758-Series VVF190100000"
local monitorSecond = "desc:ViewSonic Corporation VX2758-Series VVF201800102"

hl.monitor({ output = monitorMain, mode = "2560x1440@144", position = "auto", scale = 1, vrr = 1 })
-- , scale = 1, vrr = 1
hl.monitor({ output = monitorSecond, mode = "preferred", position = "auto-left" })

-- bind workspaces to monitors
for i = 1, 5 do
	hl.workspace_rule({
		workspace = tostring(i),

		monitor = monitorMain,
		default = i == 1,
	})

	hl.workspace_rule({
		workspace = tostring(5 + i),

		monitor = monitorSecond,
		default = i == 1,
	})
end

