local http = require"coro-http-luv"
local json = require"dkjson"
local posix = require"posix"
local Process = require"Moonrise.System.Posix.Process"
local lfs = require"lfs"
local luv = require"luv"
local Colors = require"Colors"
local SteamConfig = require"Config.Steam"
local UITree = require"UITree"

local ShadowOffset = 8

local function LaunchProcess(Program, Arguments)
	local stdin = luv.new_pipe()
	local stdout = luv.new_pipe()
	local stderr = luv.new_pipe()
	local Exited = false
	local _, PID = luv.spawn(
		Program, {
			stdio={stdin,stdout,stderr};
			args = Arguments;
		}, function(Code, Signal)
			Exited = true
			stdout:read_stop()
		end
	)
	local Routine = coroutine.create(
		function()
			stdout:read_start(
				function(_, Chunk)
					io.write(Chunk or "") --TODO pipe this to a file?
				end
			)
			repeat
				coroutine.yield()
			until Exited
		end
	)
	return Routine
end

local Config={Colors = Colors}; Config = {
	StartInFocusmode = true;
	ShadowOffset = ShadowOffset;
	CardMargin = 1;
	Inset = {
		Top = 32;
		Bottom = ShadowOffset;
	};
	CardBorder = 2;
	UnfocusedCardShrink = 30;
	CardsLeft = 1;
	CardsRight = 1;
	Colors = Colors;
	
	Launchers = {
		Native = {
			Label = "Native";
			Launch = function(Path)
				return LaunchProcess(Path)
			end;
		};
		["Wine-GE"] = {
			Label = "Wine-GE";
			Launch = function(Path)
				return LaunchProcess("/opt/wine-ge/bin/wine", {posix.realpath(Path)})
			end;
		};
		PCSX2 = {
			Label = "PCSX2";
			Launch = function(Path)
				return LaunchProcess("pcsx2-qt", {"-nogui", posix.realpath(Path)})
			end;
		};
		Wine = {
			Label = "Wine";
			Launch = function(Path)
				return LaunchProcess("wine", {posix.realpath(Path)})
			end;
		};
		Love = {
			Label = "Love2D";
			Launch = function(Path)
				return LaunchProcess("love", {posix.realpath(Path)})
			end;
		};
		Steam = {
			Label = "Steam";
			Launch = function(AppID)
				return LaunchProcess("steam",{"-applaunch",AppID})
			end;
		};
		Yuzu = {
			Label = "Yuzu";
			Launch = function(Path)
				return LaunchProcess("yuzu", {"-f", "-g", Path})
			end;
		};
		Ryujinx = {
			Label = "Ryujinx";
			Launch = function(Path)
				return LaunchProcess("ryujinx", {Path})
			end;
		};
		RetroArch_Dolphin = {
			Label = "RetroArch (Dolphin)";
			Launch = function(Path)
				return LaunchProcess("retroarch", {"-L", "dolphin", Path})
			end;
		};
		RetroArch_ParaLLEl = {
			Label = "RetroArch (ParaLLEl)",
			Launch = function(Path)
				return LaunchProcess("retroarch", {"-L", "parallel_n64", Path})
			end;
		};
		RetroArch_BSNES = {
			Label = "RetroArch (BSNES)",
			Launch = function(Path)
				return LaunchProcess("retroarch", {"-L", "bsnes", Path})
			end
		};
		RetroArch_Sameboy = {
			Label = "RetroArch (Sameboy)";
			Launch = function(Path)
				return LaunchProcess("retroarch", {"-L", "sameboy", Path})
			end;
		};
		RetroArch_mGBA = {
			Label = "RetroArch (mGBA)";
			Launch = function(Path)
				return LaunchProcess("retroarch", {"-L", "mgba", Path})
			end;
		};
		Cemu = {
			Label = "Cemu",
			Launch = function(Path)
				return LaunchProcess("cemu", {"-f", "-g", Path .."/title.tmd"})
			end
		};
	};
	
	Collections = {
		{
			Label = "Native";
			Paths = {"/home/operator/Home/Games/Native/Links"};
			Launchers = {"Native"};
		};
		{
			Label = "Windows";
			Paths = {"/home/operator/Home/Games/Windows/Links"};
			Launchers = {"Wine", "Wine-GE", "Love"};
		};
		{
			Label = "PS2";
			Paths = {"/home/operator/Home/Games/PS2"};
			Launchers = {"PCSX2"};
		};
		{
			Label = "Switch";
			Paths = {"/home/operator/Home/Games/Switch/ROMs"};
			Launchers = {"Yuzu", "Ryujinx"};
		};
		{
			Label = "Wii U";
			Paths = {"/home/operator/Home/Games/WiiU/ROMs"};
			Launchers = {"Cemu"};
		};
		{
			Label = "Wii";
			Paths = {"/home/operator/Home/Games/Wii"};
			Launchers = {"RetroArch_Dolphin"};
		};
		{
			Label = "Gamecube";
			Paths = {"/home/operator/Home/Games/Gamecube"};
			Launchers = {"RetroArch_Dolphin"};
		};
		{
			Label = "N64";
			Paths = {"/home/operator/Home/Games/N64/ROMs"};
			Launchers = {"RetroArch_ParaLLEl"};
		};
		{
			Label = "OoTMM";
			Paths = {"/home/operator/Home/Games/N64/OoTMM"};
			Launchers = {"RetroArch_ParaLLEl"};
		};
		{
			Label = "GRHM: Standard";
			Paths = {"/home/operator/Home/Games/N64/GRHM/Standard"};
			Launchers = {"RetroArch_ParaLLEl"};
		};
		{
			Label = "GRHM: Kaizo";
			Paths = {"/home/operator/Home/Games/N64/GRHM/Kaizo"};
			Launchers = {"RetroArch_ParaLLEl"};
		};
		{
			Label = "SNES";
			Paths = {"/home/operator/Home/Games/SNES/ROMs"};
			Launchers = {"RetroArch_BSNES"};
		};
		{
			Label = "Game Boy";
			Paths = {"/home/operator/Home/Games/Game Boy"};
			Launchers = {"RetroArch_Sameboy"};
		};
		{
			Label = "Game Boy Color";
			Paths = {"/home/operator/Home/Games/Game Boy Color"};
			Launchers = {"RetroArch_Sameboy"};
		};
		{
			Label = "Game Boy Advance";
			Paths = {"/home/operator/Home/Games/Game Boy Advance"};
			Launchers = {"RetroArch_mGBA"};
		};
		{
			Label = "SNES Romhacks";
			Paths = {"/home/operator/Home/Games/SNES/Hacks"};
			Launchers = {"RetroArch_BSNES"};
		};
		{
			Label = "Steam";
			Paths = {"/home/operator/.steam/steam/steamapps"};
			Launchers = {"Steam"};
			Scan = function(CollectionConfig)
				local List = {
					UITree.Output.Text("Loading", "Loading...")
				}
				coroutine.wrap(
					function()
						local url = (
							"http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=%s&steamid=%s&format=json&include_appinfo=1"
						):format(
							SteamConfig.Key, SteamConfig.UserID
						)
						local _, data = http.request("GET", url)
						local decodedResponse = json.decode(data)
						
						table.remove(List)
						
						for _, Game in pairs(decodedResponse.response.games) do
							local Installed = false
							for _, Path in pairs(CollectionConfig.Paths) do
								local Manifest = ("appmanifest_%s.acf"):format(Game.appid)
								local Fullpath = Path .."/".. Manifest
								if lfs.attributes(Fullpath) then
									Installed = true
									break
								end
							end
							
							table.insert(
								List,
								UITree.Input.Choice.Option(
									Game.name, UITree.Output.Text(
										"Name",
										Game.name .. (Installed and " [Installed]" or ""),
										{ 
											Color = Installed and Config.Colors.Steam.Installed or nil
										} 
									),
									Game.appid
								)
							)
						end
						
						table.sort(
							List, function(Left, Right)
								return Left.Name < Right.Name
							end
						)
					end
				)()
				return List
			end;
		};
	}
}; return Config
