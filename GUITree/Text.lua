local OOP = require"Moonrise.OOP"

local Text = OOP.Declarator.Shortcuts(
	"GUITree.Text", {
		require"GUITree.Element"
	}
)

function Text:Initialize(Instance, Origin, Contents, Color, Font)
	Instance.Contents = Contents
	Instance.Color = Color or {1,1,1}
	Instance.Object = love.graphics.newText(Font or love.graphics.getFont(), Contents)
		Text.Parents.Element:Initialize(Instance, Origin, {Width = Instance.Object:getWidth(), Height = Instance.Object:getHeight()})
end

function Text:Draw()
	love.graphics.setColor(self.Color)
	love.graphics.draw(self.Object)
end

return Text
