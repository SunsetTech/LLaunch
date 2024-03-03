local OOP = require"Moonrise.OOP"

local CardSet = OOP.Declarator.Shortcuts"LLaunch.CardSet"

function CardSet:Initialize(Instance, UIRoot)
	Instance.UIRoot = UIRoot
	Instance.Index = 1
end

function CardSet:ShiftLeft()
	self.Index = (self.Index-2)%#self.UIRoot.Children+1
end

function CardSet:ShiftRight()
	self.Index = self.Index%#self.UIRoot.Children+1
end

function CardSet:GetUI(Offset)
	Offset = (Offset == nil) and 0 or Offset
	return self.UIRoot.Children[(self.Index-1+Offset)%(#self.UIRoot.Children)+1]
end

return CardSet
