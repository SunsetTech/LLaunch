local lfs = require"lfs"
local UITree = require"UITree"

return function(Config)

	local CollectionElements = {}

	local Interface = UITree.Collection(
		"Collections", {},
		CollectionElements
	)

	for _, Collection in pairs(Config.Collections) do
		local LauncherOptions = {}
		for _, LauncherName in pairs(Collection.Launchers) do
			table.insert(
				LauncherOptions,
				UITree.Output.Text("Launcher Name", {}, Config.Launchers[LauncherName].Label)
			)
		end
		local LauncherSelect = UITree.Input.Choice("Collection Launcher",{},LauncherOptions)
		
		local CollectionGames = {}
		
		if Collection.Scan then
			CollectionGames, SubTotal = Collection.Scan(Collection)
		else
			for _, Path in pairs(Collection.Paths) do
				for File in lfs.dir(Path) do
					if (File ~= "." and File ~= "..") then
						local Fullpath = Path .."/".. File
						table.insert(
							CollectionGames, 
							UITree.Input.Action(
								"Launch", {},
								File,
								function()
									love.window.setFullscreen(false)
									Config.Launchers[Collection.Launchers[LauncherSelect.Selected]].Launch(Fullpath)
									love.window.setFullscreen(true, "desktop")
									AppExitedAt = love.timer.getTime()
								end
							)
						)
					end
				end
			end
		end
		table.sort(
			CollectionGames, function(Left, Right)
				return Left.Name < Right.Name
			end
		)
		table.insert(
			CollectionElements, UITree.Collection(
				Collection.Label, {},
				{
					LauncherSelect,
					UITree.Collection(
						"Games", {},
						CollectionGames
					)
				}
			)
		)
	end
	
	return Interface
end
