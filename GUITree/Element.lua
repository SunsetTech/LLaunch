local OOP = require"Moonrise.OOP"

local Element = OOP.Declarator.Shortcuts"GUITree.Element"

function Element:Initialize(Instance, Origin, Size)
	Instance.Origin = Origin
	Instance.Size = Size
	Instance.Canvas = love.graphics.newCanvas(Size.Width, Size.Height)
end

function Element:Setup()
	love.graphics.setCanvas(self.Canvas)
	love.graphics.clear()
end

function Element:Render(Canvas)
	self:Setup()
	self:Draw()
	self:Finish(Canvas)
end

function Element:Finish(Canvas)
	love.graphics.setCanvas(Canvas)
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setColor(1,1,1)
	love.graphics.draw(self.Canvas, self.Origin.X, self.Origin.Y)
	love.graphics.setBlendMode"alpha"
end

return Element
