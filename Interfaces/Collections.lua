local lfs = require"lfs"
local UITree = require"UITree"

return function(Config, Oops)
	local Deck = UITree.Collection"Collections"

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
		
		local GameSelect = UITree.Input.Choice("Game", nil, CollectionGames);
		local ListSelect = UITree.Input.Choice("List", nil, Oops.Lists);
		
		Deck:Add( 
			UITree.Collection(
				Collection.Label, nil, {
					LauncherSelect;
					GameSelect;
					UITree.Input.Action(
						"Launch", nil, 
						"Launch", function()
							local Launcher = LauncherSelect:GetValue()
							local Fullpath = GameSelect:GetValue()
							local ProcessRoutine = Config.Launchers[Launcher].Launch(Fullpath)
							Oops.AppExitedAt = love.timer.getTime()
							return ProcessRoutine, ([[Waiting for "%s" to exit]]):format(GameSelect:GetKey().Contents)
						end
					);
					UITree.Input.Action(
						"Add To Lists", nil,
						"Add To Lists", function()
							local ListSet = UITree.Collection"List Set"
							for _, List in pairs(Oops.Lists) do
								ListSet:Add(UITree.Input.Boolean(List.Name, nil, false))
							end
							return ListSet, function()
								local InsertStatement = Oops.Database:prepare"INSERT INTO ListEntries (List, Collection, Name, Identifier) VALUES (?, ?, ?, ?)"
								for _, Child in pairs(ListSet.Children) do
									if Child:GetValue() then
										Oops.ListsInterface:Find(Child.Name):Find"Game/App":Add(
											GameSelect:GetValue(),
											UITree.Output.Text("Name", nil, GameSelect:GetKey().Contents),
											{Collection.Label, GameSelect:GetValue()}
										)
										InsertStatement:bind_values(Child.Name, Collection.Label, GameSelect:GetKey().Contents, GameSelect:GetValue())
										InsertStatement:step()
										InsertStatement:reset()
									end
								end
								InsertStatement:finalize()
							end
						end
					);
				}
			)
		)
	end
	
	return Deck
end
