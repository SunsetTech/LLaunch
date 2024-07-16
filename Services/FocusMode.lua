local OOP = require"Moonrise.OOP"

local FocusMode = OOP.Declarator.Shortcuts(
	"LLaunch.Services.OBS", {
		require"Service.Worker"
	}
)

function FocusMode:Initialize(Instance)
	os.execute"i3-msg extension_focusmode on"
	os.execute"polybar-msg cmd hide"
end

function FocusMode:Stop()
	os.execute"i3-msg extension_focusmode off"
	os.execute"polybar-msg cmd show"
end

return FocusMode
