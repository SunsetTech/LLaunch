local OOP = require"Moonrise.OOP"

local Deck = OOP.Declarator.Shortcuts"LLaunch.Deck"

function Deck:Initialize(Instance, UIRoot)
	Instance.UIRoot = UIRoot
	Instance.Index = 1
end

function Deck:ShiftLeft()
	self.Index = (self.Index-2)%#self.UIRoot.Children+1
end

function Deck:ShiftRight()
	self.Index = self.Index%#self.UIRoot.Children+1
end

function Deck:GetUI(Offset)
	Offset = (Offset == nil) and 0 or Offset
	return self.UIRoot.Children[(self.Index-1+Offset)%(#self.UIRoot.Children)+1]
end

return Deck
