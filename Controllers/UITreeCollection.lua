local UITree = require"UITree"
local TextInput = require"Controllers.TextInput"

local OOP = require"Moonrise.OOP"

local UITreeCollection = OOP.Declarator.Shortcuts(
	"LLaunch.Controllers.UITreeCollection", {
		require"Controllers.Base"
	}
)

function UITreeCollection:Initialize(Instance, Focus, TextRenderTarget, Oops)
	Instance.Focus = Focus
	Instance.GamepadHeld = {}
	Instance.KeyboardHeld = {}
	Instance.NextTwitch = math.huge
	Instance.TextRenderTarget = TextRenderTarget
	Instance.Oops = Oops
end

function UITreeCollection:DrawCard(CardRoot, CardOrigin, CardSize, TextColor, CardColor, ShadowColor, BorderColor, ShadowOffset, CardBorder)
	self.TextRenderTarget:Reset()
	self.TextRenderTarget:BeginPane()
	self.TextRenderTarget:Render(CardRoot, nil, nil, true)
	local TextStrings = self.TextRenderTarget:GetPane():Render(self.Oops.ContainerHalfHeight)
	self.TextRenderTarget:EndPane()
	
	local TextObject = love.graphics.newText(love.graphics.getFont(),"")
	TextObject:add(TextStrings,0,0)
	
	CardSize = CardSize or {
		TextObject:getWidth(),
		TextObject:getHeight()
	}
	
	CardOrigin = CardOrigin or {
		love.graphics.getWidth()/2-TextObject:getWidth()/2,
		love.graphics.getHeight()/2-TextObject:getHeight()/2
	}
	
	local ShadowOrigin = {
		CardOrigin[1]-ShadowOffset,
		CardOrigin[2]-ShadowOffset
	}
	local BorderOrigin = {
		CardOrigin[1]-CardBorder,
		CardOrigin[2]-CardBorder
	}
	local BorderSize = {
		CardSize[1]+CardBorder*2,
		CardSize[2]+CardBorder*2
	}
	love.graphics.setScissor(
		ShadowOrigin[1], ShadowOrigin[2],
		CardSize[1], CardSize[2]
	)
	love.graphics.clear(ShadowColor)
	love.graphics.setScissor(
		BorderOrigin[1], BorderOrigin[2],
		BorderSize[1], BorderSize[2]
	)
	love.graphics.clear(BorderColor)
	love.graphics.setScissor(
		CardOrigin[1], CardOrigin[2],
		CardSize[1], CardSize[2]
	)
	love.graphics.clear(CardColor)
	love.graphics.setColor(TextColor)
	love.graphics.draw(
		TextObject,
		math.floor(CardOrigin[1]), math.floor(CardOrigin[2])
	)
	love.graphics.setScissor()
end

function UITreeCollection:InvokeAction(Element)
	local Returned, Submit = Element:Execute()
	if Returned then
		if OOP.Reflection.Type.Of(UITree.Base, Returned) then
			table.insert(
				self.Oops.DialogStack,
				require"Controllers.Modal"(
					Returned, Submit or function() print"???" end,
					self.Config,
					self.Colors,
					self.Oops
				)
			)
		elseif type(Returned) == "thread" then
			table.insert(
				self.Oops.DialogStack,
				require"Controllers.Wait"(Returned, Submit, self.Oops.DialogStack)
			)
		elseif OOP.Reflection.Type.Of(UITreeCollection.Parents.Base, Returned) then
			table.insert(self.Oops.DialogStack, Returned)
		end
	end
end

function UITreeCollection:KeyPressed(Key, Scancode, IsRepeat)
	self.KeyboardHeld[Key] = true
	local CurrentFocus = self.Focus:GetFocus()
	if Key == "return" then
		if (OOP.Reflection.Type.Of(UITree.Input.Action, CurrentFocus)) then
			self:InvokeAction(CurrentFocus)
		elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, CurrentFocus) then
			CurrentFocus:SetValue(not CurrentFocus:GetValue())
		elseif OOP.Reflection.Type.Of(UITree.Input.String, CurrentFocus) then
			table.insert(
				self.Oops.DialogStack,
				TextInput(CurrentFocus, self.Oops.DialogStack)
			)
		end
	elseif Key == "down" then
		self.Focus:SwitchNextFocus()
		self.NextTwitch = love.timer.getTime() + 0.25
	elseif Key == "up" then
		self.Focus:SwitchPrevFocus()
		self.NextTwitch = love.timer.getTime() + 0.25
	elseif Key == "left" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected > 1 then
		CurrentFocus.Selected = CurrentFocus.Selected - 1
		self.NextTwitch = love.timer.getTime() + 0.25
	elseif Key == "right" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected < #CurrentFocus.Children then
		CurrentFocus.Selected = CurrentFocus.Selected + 1
		self.NextTwitch = love.timer.getTime() + 0.25
	end
end

function UITreeCollection:KeyReleased(Key, Scancode)
	self.KeyboardHeld[Key] = false
end

function UITreeCollection:GamepadPressed(Controller, Button)
	self.GamepadHeld[Button] = true
	local CurrentFocus = self.Focus:GetFocus()
	
	if Button == "dpdown" then
		self.Focus:SwitchNextFocus()
		self.NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpup" then
		self.Focus:SwitchPrevFocus()
		self.NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpleft" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected > 1 then
		CurrentFocus.Selected = CurrentFocus.Selected - 1
		self.NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpright" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected < #CurrentFocus.Children then
		CurrentFocus.Selected = CurrentFocus.Selected + 1
		self.NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "b" or Button == "a" or Button == "x" or Button == "y" then
		if (OOP.Reflection.Type.Of(UITree.Input.Action, CurrentFocus)) then
			self:InvokeAction(CurrentFocus)
		elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, CurrentFocus) then
			CurrentFocus:SetValue(not CurrentFocus:GetValue())
		elseif OOP.Reflection.Type.Of(UITree.Input.String, CurrentFocus) then
			table.insert(
				self.Oops.DialogStack,
				TextInput(CurrentFocus, self.Oops.DialogStack)
			)
		end
	end
end

function UITreeCollection:GamepadReleased(Controller, Button)
	self.GamepadHeld[Button] = false
end

function UITreeCollection:Update(Delta)
	local CurrentFocus = self.Focus:GetFocus()
	
	if love.timer.getTime() >= self.NextTwitch then
		if self.GamepadHeld.dpup or self.KeyboardHeld.up then
			self.Focus:SwitchPrevFocus()
			self.NextTwitch = love.timer.getTime() + 0.025
		elseif self.GamepadHeld.dpdown or self.KeyboardHeld.down then
			self.Focus:SwitchNextFocus()
			self.NextTwitch = love.timer.getTime() + 0.025
		elseif (self.GamepadHeld.dpleft or self.KeyboardHeld.left) and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected > 1 then
			CurrentFocus.Selected = CurrentFocus.Selected - 1
			self.NextTwitch = love.timer.getTime() + 0.025
		elseif (self.GamepadHeld.dpright or self.KeyboardHeld.right) and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected < #CurrentFocus.Children then
			CurrentFocus.Selected = CurrentFocus.Selected + 1
			self.NextTwitch = love.timer.getTime() + 0.025
		end
	end
end

return UITreeCollection
