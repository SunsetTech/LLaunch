local lfs = require"lfs"
local UITree = require"UITree"

return function(Config, Oops)
	local Deck = UITree.Collection"Collections"

	for _, Collection in pairs(Config.Collections) do
		local LauncherSelect = UITree.Input.Choice"Launcher"
		for _, LauncherName in pairs(Collection.Launchers) do
			LauncherSelect:Add(
				"Launcher",
				UITree.Output.Text("Launcher Name", Config.Launchers[LauncherName].Label),
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
								UITree.Output.Text("Subpath", File),
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
		
		local GameSelect = UITree.Input.Choice("Game", CollectionGames);
		
		Deck:Add( 
			UITree.Collection(
				Collection.Label, {
					LauncherSelect;
					GameSelect;
					UITree.Input.Action(
						"Launch", function()
							local Launcher = LauncherSelect:GetValue()
							local Fullpath = GameSelect:GetValue()
							if Oops.Streaming then 
								return UITree.Output.Text("Confirm","Remember to change stream title and category"), function()
									local ProcessRoutine = Config.Launchers[Launcher].Launch(Fullpath)
									Oops.AppExitedAt = love.timer.getTime()
									return ProcessRoutine, ([[Running "%s"]]):format(GameSelect:GetKey().Contents)
								end
							else
								local ProcessRoutine = Config.Launchers[Launcher].Launch(Fullpath)
								Oops.AppExitedAt = love.timer.getTime()
								return ProcessRoutine, ([[Running "%s"]]):format(GameSelect:GetKey().Contents)
							end
						end
					);
					UITree.Input.Action(
						"Add To Lists", function()
							local ListSet = UITree.Collection"List Set"
							for _, List in pairs(Oops.Lists) do
								ListSet:Add(UITree.Input.Boolean(List.Name, false))
							end
							return ListSet, function()
								local InsertStatement = Oops.Database:prepare"INSERT INTO ListEntries (List, Collection, Name, Identifier) VALUES (?, ?, ?, ?)"
								for _, Child in pairs(ListSet.Children) do
									---@cast Child UITree.Input.Boolean
									if Child:GetValue() then
										Oops.ListsInterface:Find(Child.Name):Find"Game/App":Add(
											GameSelect:GetValue(),
											UITree.Output.Text("Name", GameSelect:GetKey().Contents),
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
