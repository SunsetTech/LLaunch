local posix = require"posix"
local luv = require"luv"

local UITree = require"UITree"
local GamerMode = require"Services.GamerMode"
local OBS = require"Services.OBS"
local Program = require"Service.Program"

local function checkPolybarAndI3()
	-- Check if Polybar is running
	local polybarReturnCode = os.execute("pgrep -x polybar > /dev/null")

	-- Check if i3 is running
	local i3ReturnCode = os.execute("pgrep -x i3 > /dev/null")

	-- Return true if both Polybar and i3 are running, otherwise false
	return polybarReturnCode == 0 and i3ReturnCode == 0
end

local function detectSteam()
    local steamPid = io.popen("pgrep -x steam"):read("*a")
    if steamPid ~= "" then
        return tonumber(steamPid)
    else
        return nil
    end
end

-- Function to detect OBS and return its PID
local function detectOBS()
    local obsPid = io.popen("pgrep -x obs"):read("*a")
    if obsPid ~= "" then
        return tonumber(obsPid)
    else
        return nil
    end
end

return function(Config, Services)
	local GamermodeService
	local GamermodeActive = UITree.Output.Boolean("Active",{},false)
	if Config.StartInGamermode then
		GamermodeService = GamerMode()
		GamermodeActive.Value = true
		Services:Add(GamermodeService)
	end

	local GamermodeInterface = UITree.Collection(
		"Gamer Mode", {}, {
			GamermodeActive,
			UITree.Input.Action(
				"Enable/Disable", {}, "Enable/Disable", function()
					if GamermodeActive:GetValue() then
						assert(GamermodeService)
						Services:StopAndRemove(GamermodeService)
						GamermodeActive.Value = false
						GamermodeService = nil
					else
						GamermodeService = GamerMode()
						GamermodeActive.Value = true
						Services:Add(GamermodeService)
					end
				end
			)
		}
	)

	local OBSRunning = UITree.Output.Boolean("Running",{},false)
	local OBSService
	local StartOBSStreaming = UITree.Input.Boolean("Start streaming on launch", {}, false)

	local OBSInterface = UITree.Collection(
		"OBS", {}, {
			OBSRunning,
			StartOBSStreaming,
			UITree.Input.Action(
				"Start/Stop", {}, "Start/Stop", function() --TODO steam takes a while to be ready to launch games and shutdown when told, a spinner would be nice but this requires a bit of architecting
					if OBSRunning:GetValue() then
						Services:StopAndRemove(OBSService)
						OBSRunning.Value = false
						OBSService = nil
					else
						OBSService = OBS(StartOBSStreaming:GetValue(), "SoonSoon", 4455, "wiorfajesfoijdsfioasji")
						Services:Add(OBSService)
						OBSRunning.Value = true
					end
				end
			)
		}
	)

	local SteamRunning = UITree.Output.Boolean("Running",{},false)
	local SteamReady = UITree.Output.Boolean("Launching ready",{},false)
	local SteamService

	local SteamInterface = UITree.Collection(
		"Steam", {}, {
			SteamRunning,
			SteamReady,
			UITree.Input.Action(
				"Start/Stop", {}, "Start/Stop", function()
					if SteamRunning:GetValue() then
						Services:StopAndRemove(SteamService)
						SteamReady.Value = false
						
						local SteamOutput = SteamService.Output
						local OutputPoller = luv.new_poll(SteamOutput)
						luv.poll_start(
							OutputPoller, "rd",
							function(Error, Events)
								if luv.fs_read(SteamOutput,1) == "" then
									SteamRunning.Value = false
									luv.poll_stop(OutputPoller)
								end
							end
						)
						SteamService = nil
					else
						SteamService = Program("steam", {"-silent"})
						Services:Add(SteamService)
						SteamRunning.Value = true
						local ReadyOutput = "BuildCompleteAppOverviewChange"
						local Buffer = string.rep(" ", #ReadyOutput)
						local SteamError = SteamService.Error
						local OutputPoller = luv.new_poll(SteamError)
						luv.poll_start(
							OutputPoller, "rd",
							function(Error, Events)
								local Byte = luv.fs_read(SteamError, 1)
								Buffer = Buffer:sub(2) .. Byte
								if Buffer == ReadyOutput then
									SteamReady.Value = true
									luv.poll_stop(OutputPoller)
								end
							end
						)
					end
				end
			)
		}
	)

	local ServiceInterfaces = {
		OBSInterface,
		SteamInterface
	}

	if checkPolybarAndI3() then
		table.insert(ServiceInterfaces, GamermodeInterface)
	end

	return UITree.Collection(
		"Settings", {}, {
			UITree.Collection("Services", {}, ServiceInterfaces)
		}
	)
end
