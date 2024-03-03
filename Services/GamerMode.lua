local OOP = require"Moonrise.OOP"

local GamerMode = OOP.Declarator.Shortcuts(
	"LLaunch.Services.OBS", {
		require"Service.Worker"
	}
)

function GamerMode:Initialize(Instance)
	os.execute"i3-msg gamermode on"
	os.execute"polybar-msg cmd hide"
end

function GamerMode:Stop()
	os.execute"i3-msg gamermode off"
	os.execute"polybar-msg cmd show"
end

return GamerMode
