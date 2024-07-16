local UITree = require"UITree"

local function ListCard(Name, Config, Oops)
	local AppSelection = UITree.Input.Choice"Game/App"
	return UITree.Collection(
		Name, {
			AppSelection;
			UITree.Input.Action(
				"Launch", function()
					local Details = AppSelection:GetValue()
					local LauncherSelect = UITree.Input.Choice"Launcher"
					for _, Collection in pairs(Config.Collections) do
						if Collection.Label == Details[1] then
							for _, LauncherName in pairs(Collection.Launchers) do
								LauncherSelect:Add(LauncherName,UITree.Output.Text("Name", LauncherName),LauncherName)
							end
							return LauncherSelect, function(Root)
								local Launcher = Root:GetValue()
								Config.Launchers[Launcher].Launch(Details[2])
								Oops.AppExitedAt = love.timer.getTime()
							end
						end
					end
				end
			);
			UITree.Input.Action(
				"Add Games", function()
					--local CollectionsDeck = Oops.Decks:Find"Collections"
					local CollectionSelection = UITree.Input.Choice"List Select"
					for _, Collection in pairs(Config.Collections) do
						CollectionSelection:Add(Collection.Label, UITree.Output.Text(Collection.Label, Collection.Label), Collection.Label) --TODO this sucks
					end
					return CollectionSelection, function()
						local CollectionCard = Oops.Decks:Find"Collections":Find(CollectionSelection:GetValue())
						local GameSet = UITree.Collection"Game Set"
						for _, GameOption in pairs(CollectionCard:Find"Game".Children) do
							GameSet:Add(UITree.Input.Boolean(GameOption.Name, false))
						end
						return GameSet, function()
							local InsertStatement = Oops.Database:prepare"INSERT INTO ListEntries (List, Collection, Name, Identifier) VALUES (?, ?, ?, ?)"
							for _, GameEntry in pairs(GameSet.Children) do
								---@cast GameEntry UITree.Input.Boolean
								if GameEntry:GetValue() then
									local Identifier = CollectionCard:Find"Game":Find(GameEntry.Name).Value
									AppSelection:Add(
										GameEntry.Name,
										UITree.Output.Text("Name", GameEntry.Name),
										{CollectionSelection:GetValue(), Identifier}
									)
									InsertStatement:bind_values(Name, CollectionSelection:GetValue(), GameEntry.Name, Identifier)
									InsertStatement:step()
									InsertStatement:reset()
								end
							end
							InsertStatement:finalize()
						end
					end
				end
			)
		}
	)
end

return function(Config, Oops)
	local ListSelection = UITree.Input.Choice"List Selection"
	local Deck = UITree.Collection"List Deck"
	
	Deck:Add(
		UITree.Collection(
			"List Management", {
				UITree.Input.Action(
					"New", function()
						return UITree.Input.String("List Name", "New List"), function(Root)
							ListSelection:Add(
								Root:GetValue(),
								UITree.Output.Text("List Name", Root:GetValue()),
								Root:GetValue()
							)
							Deck:Add(ListCard(Root:GetValue(), Config, Oops))
							ListSelection.Selected = math.min(math.max(ListSelection.Selected,1),#ListSelection.Children)
						end
					end
				),
				ListSelection,
				UITree.Input.Action(
					"Delete", function()
						return UITree.Output.Text("Confirmation", "Are you sure you want to delete that?"), function(Root)
							Deck:Remove(ListSelection:GetValue())
							local DeleteStatement = Oops.Database:prepare[[DELETE FROM ListEntries WHERE List = ?]]
							DeleteStatement:bind_values(ListSelection:GetValue())
							DeleteStatement:step()
							DeleteStatement:finalize()
							ListSelection:Remove(ListSelection.Selected)
							ListSelection.Selected = math.min(math.max(ListSelection.Selected,1),#ListSelection.Children)
						end
					end
				)
			}
		)
	)
	
	for Row in Oops.Database:nrows("SELECT DISTINCT List FROM ListEntries") do
		ListSelection:Add(Row.List, UITree.Output.Text("Name", Row.List), Row.List)
		local SelectStatement = Oops.Database:prepare"SELECT * FROM ListEntries WHERE List = ?"
		local Card = ListCard(Row.List, Config, Oops)
		SelectStatement:bind_values(Row.List)
		for Row in SelectStatement:nrows() do
			local AppSelection = Card:Find"Game/App"
			---@cast AppSelection UITree.Input.Choice
			AppSelection:Add(
				Row.Identifier,
				UITree.Output.Text("Name", Row.Name),
				{Row.Collection, Row.Identifier}
			)
		end
		Deck:Add(Card)
	end
	
	return Deck, ListSelection.Children
end
