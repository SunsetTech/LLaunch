local OOP = require"Moonrise.OOP"

local Square = OOP.Declarator.Shortcuts(
	"GUITree.Square", {
		require"GUITree.Element"
	}
)

function Square:Initialize(Instance, Origin, Size, Color)
		Square.Parents.Element:Initialize(Instance, Origin, Size)
	Instance.Color = Color
end

function Square:Draw()
	love.graphics.clear(self.Color)
end

return Square
