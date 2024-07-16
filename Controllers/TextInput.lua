local InputField = require"InputField.InputField" 

local OOP = require"Moonrise.OOP"

local TextInput = OOP.Declarator.Shortcuts(
	"LLaunch.Controllers.TextInput", {
		require"Controllers.Base"
	}
)

function TextInput:Initialize(Instance, UIElement, DialogStack, BlinkCycle)
	Instance.UIElement = UIElement
	Instance.Field = InputField(UIElement:GetValue() or "")
	Instance.Field:setType"multiwrap"
	Instance.BlinkCycle = BlinkCycle or 0.6
	Instance.DialogStack = DialogStack
	Instance.Title = love.graphics.newText(love.graphics.getFont(), "Enter or Gamepad 'A' to Submit, Escape or Gamepad 'B' to Cancel\n".. UIElement.Name ..":")
	Instance.Field:setWidth(Instance.Title:getWidth())
	Instance.Field:setCursor(Instance.Field:getTextLength()+1)
end

function TextInput:GetSize()
	return {
		self.Field:getWidth()+1;
		self.Field:getTextHeight()+2;
	}

end

function TextInput:GetOrigin()
	local Size = self:GetSize()
	return {
		love.graphics.getWidth()/2-Size[1]/2;
		love.graphics.getHeight()/2-Size[2]/2;
	}
end

function TextInput:KeyPressed(Key, ScanCode, IsRepeat)
	if (Key == "return") then
		table.remove(self.DialogStack)
		self.UIElement:SetValue(self.Field:getText())
	elseif (Key == "escape") then
		table.remove(self.DialogStack)
	else
		self.Field:keypressed(Key, IsRepeat)
	end
end

function TextInput:TextInput(Text)
	self.Field:textinput(Text)
end

function TextInput:MousePressed(X, Y, Button, Count)
	local Origin = self:GetOrigin()
	self.Field:mousepressed(X-Origin[1],Y-Origin[2],Button,Count)
end

function TextInput:MouseMoved(X, Y)
	local Origin = self:GetOrigin()	
	self.Field:mousemoved(X-Origin[1], Y-Origin[2])
end

function TextInput:MouseReleased(X, Y, Button)
	local Origin = self:GetOrigin()
	self.Field:mousereleased(X-Origin[1], Y-Origin[2], Button)
end

function TextInput:WheelMoved(DeltaX, DeltaY)
	self.Field:wheelmoved(DeltaX, DeltaY)
end

function TextInput:GamepadPressed(Controller, Button)
	if (Button == "a") then
		table.remove(self.DialogStack)
		self.UIElement:SetValue(self.Field:getText())
	elseif (Button == "b") then
		table.remove(self.DialogStack)
	end
end

function TextInput:Draw()
	local Size = self:GetSize()
	local Origin = self:GetOrigin()
	love.graphics.rectangle("fill", Origin[1], Origin[2] - self.Title:getHeight(), Size[1], self.Title:getHeight())
	love.graphics.setColor(0,0,0)
	love.graphics.draw(self.Title, Origin[1], Origin[2] - self.Title:getHeight())
	love.graphics.setScissor(Origin[1], Origin[2], Size[1], Size[2])
	love.graphics.setColor(1,1,1)
	love.graphics.rectangle("fill", Origin[1], Origin[2], Size[1], Size[2])
	
	love.graphics.setColor(0, 0, 1)
	for _, x, y, w, h in self.Field:eachSelection() do
		love.graphics.rectangle("fill", Origin[1] + x, Origin[2] + y, w, h+2)
	end

	love.graphics.setColor(0,0,0)
	self.Field:setFont(love.graphics.getFont())
	for _, text, x, y in self.Field:eachVisibleLine() do
		love.graphics.print(text, Origin[1] + x, Origin[2] + y)
	end
	if (self.Field:getBlinkPhase()%self.BlinkCycle)<(self.BlinkCycle/2) then
		local x, y, h = self.Field:getCursorLayout()
		love.graphics.rectangle("fill", Origin[1] + x, Origin[2] + y, 1, h+2)
	end
	love.graphics.setScissor()
end

return TextInput
