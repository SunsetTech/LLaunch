local lanes = require"lanes".configure()
local http = require("coro-http-luv")
local ltn12 = require("ltn12")
local json = require("dkjson")
local lfs = require"lfs"
local Colors = require"Colors"
local SteamConfig = require"SteamConfig"
print(Colors)
require"Moonrise.Import.Install".All() --forget if this is needed
local UITree = require"UITree"

local ShadowOffset = 8
local Config={Colors = Colors}; Config = {
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
				os.execute(
					([["%s"]]):format(Path)
				)
			end;
		};
		Steam = {
			Label = "Steam";
			Launch = function(AppID)
				os.execute(
					([[steam -applaunch %i]]):format(AppID)
				)
			end;
		};
		Yuzu = {
			Label = "Yuzu";
			Launch = function(Path)
				os.execute(
					([[yuzu -f -g "%s"]]):format(Path)
				)
			end;
		};
		Ryujinx = {
			Label = "Ryujinx";
			Launch = function(Path)
				os.execute(
					([[Ryujinx "%s"]]):format(Path)
				)
			end;
		};
		RetroArch_Dolphin = {
			Label = "RetroArch (Dolphin)";
			Launch = function(Path)
				os.execute(
					([[retroarch -L dolphin "%s"]]):format(Path)
				)
			end;
		};
		RetroArch_ParaLLEl = {
			Label = "RetroArch (ParaLLEl)",
			Launch = function(Path)
				os.execute(
					([[retroarch -L parallel_n64 "%s"]]):format(Path)
				)
			end;
		};
		RetroArch_BSNES = {
			Label = "RetroArch (BSNES)",
			Launch = function(Path)
				os.execute(
					([[retroarch -L bsnes "%s"]]):format(Path)
				)
			end
		};
		Cemu = {
			Label = "Cemu",
			Launch = function(Path)
				os.execute(
					([[cemu -f -g "%s/title.tmd"]]):format(Path)
				)
			end
		};
	};
	
	Collections = {
		--[[{
			Label = "Switch (Yuzu)";
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
			Paths = {"/home/operator/Home/Games/N64"};
			Launchers = {"RetroArch_ParaLLEl"};
		};
		{
			Label = "SNES";
			Paths = {"/home/operator/Home/Games/SNES/ROMs"};
			Launchers = {"RetroArch_BSNES"};
		};]]
		{
			Label = "SNES Romhacks";
			Paths = {"/home/operator/Home/Games/SNES/Hacks"};
			Launchers = {"RetroArch_BSNES"};
		};
		{
			Label = "Native";
			Paths = {"/home/operator/Home/Games/Native/Links"};
			Launchers = {"Native"};
		};
		{
			Label = "Steam";
			Paths = {"/home/operator/.steam/steam/steamapps"};
			Launchers = {"Steam"};
			Scan = function(CollectionConfig)
				local CollectionTotal = 0
				local List = {
					UITree.Element.Text("Loading",{},"Loading...")
				}
				coroutine.wrap(
					function()
						local url = string.format("http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=%s&steamid=%s&format=json&include_appinfo=1", SteamConfig.Key, SteamConfig.UserID)
						local res, data = http.request("GET", url)
						table.remove(List)
						local decodedResponse = json.decode(data)
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
							CollectionTotal = CollectionTotal + 1
							table.insert(
								List,
								UITree.Element.Action(
									Game.name, {Color = Installed and Config.Colors.Steam.Installed or nil}, Game.name .. (Installed and " [Installed]" or ""),
									function()
										love.window.setFullscreen(false)
										Config.Launchers.Steam.Launch(Game.appid)
										AppExitedAt = os.time()
									end
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
