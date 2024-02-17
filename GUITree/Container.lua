local OOP = require"Moonrise.OOP"

local Container = OOP.Declarator.Shortcuts(
	"GUITree.Container", {
		require"GUITree.Element"
	}
)

function Container:Initialize(Instance, Origin, Size, Children)
		Container.Parents.Element:Initialize(Instance, Origin, Size)
	Instance.Children = Children or {}
end

function Container:Draw()
	for _, Child in pairs(self.Children) do
		Child:Render(self.Canvas)
	end
end

return Container
