local UITree = require"UITree"

return function(_, Collections)
	local Lists = {}
	
	local CollectionSelection = UITree.Input.Choice"Collection Selection"
	for _, Child in pairs(Collections.Children) do
		CollectionSelection:Add(
			UITree.Output.Text("Name", {}, Child.Name)
		)
	end

	local ListSelection = UITree.Input.Choice"List Selection"
	
	return UITree.Collection(
		"Lists", {}, {
			CollectionSelection,
			ListSelection,
			UITree.Input.Action(
				"New", {}, "New",
				function()
					return UITree.Input.Form(
						"New List", {},
						UITree.Input.Text"Name",
						function(Root)
							ListSelection:Add(
								UITree.Output.Text("List Name", {}, Root:GetValue())
							)
						end
					)
				end
			),
			UITree.Input.Action(
				"Add", {}, "Add", 
				function()
				end
			),
			UITree.Input.Action(
				"Remove", {}, "Remove",
				function()
				end
			)
		}
	)
end
