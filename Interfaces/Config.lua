local posix = require"posix"
local luv = require"luv"

local UITree = require"UITree"
local FocusMode = require"Services.FocusMode"
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

return function(Config, Services, Oops)
	local OBSRunning = UITree.Output.Boolean("Running",false)
	local OBSService
	local StartOBSStreaming = UITree.Input.Boolean("Start streaming on launch", false)
	local StartOBSRecording = UITree.Input.Boolean("Start recording on launch", false)
	local OBSInterface = UITree.Collection(
		"OBS", {
			OBSRunning,
			StartOBSStreaming,
			StartOBSRecording,
			UITree.Input.Action(
				"Start/Stop", function()
					if OBSRunning:GetValue() then
						Services:StopAndRemove(OBSService)
						OBSRunning.Value = false
						OBSService = nil
						Oops.Streaming = false
					else
						OBSService = OBS(StartOBSStreaming:GetValue(), StartOBSRecording:GetValue(), "SoonSoon", 4455, "boners69")
						if StartOBSStreaming:GetValue() then
							Oops.Streaming = true
						end
						Services:Add(OBSService)
						OBSRunning.Value = true
					end
				end
			)
		}
	)

	local SteamRunning = UITree.Output.Boolean("Running", false)
	local SteamReady = UITree.Output.Boolean("Launching ready", false)
	local SteamService

	local SteamInterface = UITree.Collection(
		"Steam", {
			SteamRunning,
			SteamReady,
			UITree.Input.Action(
				"Start/Stop", function()
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

	local FocusmodeService
	local FocusmodeActive = UITree.Output.Boolean("Active", false)
	if Config.StartInFocusmode then
		FocusmodeService = FocusMode()
		FocusmodeActive.Value = true
		Services:Add(FocusmodeService)
	end

	local FocusmodeInterface = UITree.Collection(
		"Focus Mode", {
			FocusmodeActive,
			UITree.Input.Action(
				"Enable/Disable", function()
					if FocusmodeActive:GetValue() then
						assert(FocusmodeService)
						Services:StopAndRemove(FocusmodeService)
						FocusmodeActive.Value = false
						FocusmodeService = nil
					else
						FocusmodeService = FocusMode()
						FocusmodeActive.Value = true
						Services:Add(FocusmodeService)
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
		table.insert(ServiceInterfaces, FocusmodeInterface)
	end

	return UITree.Collection(
		"Settings", {
			UITree.Collection("Services", ServiceInterfaces)
		}
	)
end
