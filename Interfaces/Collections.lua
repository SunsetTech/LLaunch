local lfs = require"lfs"
local UITree = require"UITree"

return function(Config, Oops)
	local Interface = UITree.Collection"Collections"

	for _, Collection in pairs(Config.Collections) do
		local LauncherSelect = UITree.Input.Choice"Launcher"
		for _, LauncherName in pairs(Collection.Launchers) do
			LauncherSelect:Add(
				"Launcher",
				UITree.Output.Text("Launcher Name", {}, Config.Launchers[LauncherName].Label),
				LauncherName
			)
		end
		
		local CollectionGames = {}
		
		if Collection.Scan then
			CollectionGames = Collection.Scan(Collection)
		else
			for _, Path in pairs(Collection.Paths) do
				for File in lfs.dir(Path) do
					if (File ~= "." and File ~= "..") then
						local Fullpath = Path .."/".. File
						table.insert(
							CollectionGames, 
							UITree.Input.Choice.Option(
								File,
								UITree.Output.Text("Subpath", {}, File),
								Fullpath
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
		
		Interface:Add( 
			UITree.Input.Form(
				Collection.Label, UITree.Collection(
					"Inputs", nil, {
						LauncherSelect,
						UITree.Input.Choice("Game", nil, CollectionGames)
					}
				),
				"Launch", function(Root)
					local Launcher = Root:Find"Launcher":GetValue()
					local Fullpath = Root:Find"Game":GetValue()
					Config.Launchers[Launcher].Launch(Fullpath)
					Oops.AppExitedAt = love.timer.getTime()
				end
			)
		)
	end
	
	return Interface
end
