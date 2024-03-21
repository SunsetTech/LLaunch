local FocusHandler = require"FocusHandler"

local OOP = require"Moonrise.OOP"

local Set = OOP.Declarator.Shortcuts"LLaunch.Controllers.Set"

function Set:Initialize(Instance, Decks, ActiveIndex, Focus)
	Instance.Decks = Decks or {}
	Instance.ActiveIndex = ActiveIndex or 1
	Instance.Focus = Focus or FocusHandler()
end

function Set:GetActiveDeck()
	return self.Decks[self.ActiveIndex]
end

function Set:GamepadPressed(Controller, Button)
	local CurrentFocus = self.Focus:GetFocus()
	if (Controller:isGamepadDown"guide") then
		if Controller:isGamepadDown"dpup" then
			self.ActiveIndex = math.max(self.ActiveIndex-1,1)
			self.Focus:Clear()
			self.Focus:PushFocus(self:GetActiveDeck():GetUI(), 0)
		elseif Controller:isGamepadDown"dpdown" then
			self.ActiveIndex = math.min(self.ActiveIndex+1,#self.Decks)
			self.Focus:Clear()
			self.Focus:PushFocus(self:GetActiveDeck():GetUI(), 0)
		end
	end
	self:GetActiveDeck():GamepadPressed(Controller, Button)
end

function Set:GamepadReleased(Controller, Button)
	self:GetActiveDeck():GamepadReleased(Controller, Button)
end

function Set:Update(Delta)
	self:GetActiveDeck():Update(Delta)
end

return Set
