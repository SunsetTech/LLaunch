local FocusHandler = require"FocusHandler"

local OOP = require"Moonrise.OOP"

local Deck = OOP.Declarator.Shortcuts"LLaunch.Controllers.Deck"

function Deck:Initialize(Instance, Cards, Index, Focus)
	Instance.Cards = Cards or {}
	Instance.Index = Index or 1
	Instance.Focus = Focus or FocusHandler()
end

function Deck:ShiftLeft()
	self.Index = (self.Index-2)%#self.Cards+1
	self.Focus:Clear()
	self.Focus:PushFocus(self:GetUI(), 0)
	self.Focus:SwitchNextFocus()
end

function Deck:ShiftRight()
	self.Index = self.Index%#self.Cards+1
	self.Focus:Clear()
	self.Focus:PushFocus(self:GetUI(), 0)
	self.Focus:SwitchNextFocus()
end

function Deck:GetUI(Offset)
	Offset = (Offset == nil) and 0 or Offset
	return self.Cards[(self.Index-1+Offset)%(#self.Cards)+1]
end

function Deck:GamepadPressed(Controller, Button)
	if Button == "leftshoulder" then
		self:ShiftLeft()
	elseif Button == "rightshoulder" then
		self:ShiftRight()
	else
		self:GetUI():GamepadPressed(Controller, Button)
	end
end

function Deck:GamepadReleased(Controller, Button)
	self:GetUI():GamepadReleased(Controller, Button)
end

function Deck:Update(Delta)
	for _, Card in pairs(self.Cards) do
		Card:Update(Delta)
	end
end

return Deck
