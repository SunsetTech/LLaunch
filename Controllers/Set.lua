local FocusHandler = require"FocusHandler"
local TextMode = require"Renderers.TextMode"
local UITree = require"UITree"

local Modal = require"Controllers.Modal"

local OOP = require"Moonrise.OOP"

local Set = OOP.Declarator.Shortcuts(
	"LLaunch.Controllers.Set", {
		require"Controllers.UITreeCollection"
	}
)

Set.Deck = OOP.Declarator.Shortcuts"LLaunch.Controllers.Set.Deck"

function Set.Deck:Initialize(Instance, CardsRoot, Index)
	Instance.CardsRoot = CardsRoot
	Instance.Index = Index or 1
end

function Set.Deck:ShiftLeft()
	self.Index = (self.Index-2)%#self.CardsRoot.Children+1
end

function Set.Deck:ShiftRight()
	self.Index = self.Index%#self.CardsRoot.Children+1
end

function Set.Deck:ActiveCard(Offset)
	Offset = (Offset == nil) and 0 or Offset
	return self.CardsRoot.Children[(self.Index-1+Offset)%(#self.CardsRoot.Children)+1]
end

function Set:Initialize(Instance, Decks, ActiveIndex, Config, Colors, Oops)
	Instance.Decks = Decks or {}
	Instance.ActiveIndex = ActiveIndex or 1
	local Focus = FocusHandler()
		Set.Parents.UITreeCollection:Initialize(Instance, Focus, TextMode(Colors.Text, Oops, Focus), Oops)
	Instance.Focus:PushFocus(Instance:ActiveDeck():ActiveCard(), 0)
	Instance.Focus:SwitchNextFocus()
	Instance.Config = Config
	Instance.Colors = Colors
end

function Set:ActiveDeck()
	return self.Decks[self.ActiveIndex]
end

function Set:ShiftLeft()
	self:ActiveDeck():ShiftLeft()
	self.Focus:Clear()
	self.Focus:PushFocus(self:ActiveDeck():ActiveCard(), 0)
	self.Focus:SwitchNextFocus()
end

function Set:ShiftRight()
	self:ActiveDeck():ShiftRight()
	self.Focus:Clear()
	self.Focus:PushFocus(self:ActiveDeck():ActiveCard(), 0)
	self.Focus:SwitchNextFocus()
end

function Set:KeyPressed(Key, Scancode, IsRepeat)
	if love.keyboard.isDown"lshift" or love.keyboard.isDown"rshift" then
		if Key == "up" then
			self.ActiveIndex = math.max(self.ActiveIndex-1,1)
			self.Focus:Clear()
			self.Focus:PushFocus(self:ActiveDeck():ActiveCard(), 0)
			self.Focus:SwitchNextFocus()
		elseif Key == "down" then
			self.ActiveIndex = math.min(self.ActiveIndex+1,#self.Decks)
			self.Focus:Clear()
			self.Focus:PushFocus(self:ActiveDeck():ActiveCard(), 0)
			self.Focus:SwitchNextFocus()
		elseif Key == "left" then
			self:ShiftLeft()
		elseif Key == "right" then
			self:ShiftRight()
		else
			Set.Parents.UITreeCollection.KeyPressed(self, Key, Scancode, IsRepeat)
		end
	else
		Set.Parents.UITreeCollection.KeyPressed(self, Key, Scancode, IsRepeat)
	end
end

function Set:GamepadPressed(Controller, Button)
	if (Controller:isGamepadDown"guide") then
		if Controller:isGamepadDown"dpup" then
			self.ActiveIndex = math.max(self.ActiveIndex-1,1)
			self.Focus:Clear()
			self.Focus:PushFocus(self:ActiveDeck():ActiveCard(), 0)
			self.Focus:SwitchNextFocus()
		elseif Controller:isGamepadDown"dpdown" then
			self.ActiveIndex = math.min(self.ActiveIndex+1,#self.Decks)
			self.Focus:Clear()
			self.Focus:PushFocus(self:ActiveDeck():ActiveCard(), 0)
			self.Focus:SwitchNextFocus()
		end
	elseif Button == "leftshoulder" then
		self:ShiftLeft()
	elseif Button == "rightshoulder" then
		self:ShiftRight()
	else
		local Returned, Submit = Set.Parents.UITreeCollection.GamepadPressed(self, Controller, Button)
		if Returned and OOP.Reflection.Type.Of(UITree.Base, Returned) then
			table.insert(
				self.Oops.DialogStack,
				Modal(
					Returned, Submit or function() print"???" end,
					self.Config,
					self.Colors,
					self.Oops
				)
			)
		end
	end
end

function Set:Draw()
	for Offset = -self.Config.CardsLeft, self.Config.CardsRight do
		local CardRoot = self:ActiveDeck():ActiveCard(Offset)
				
		local CardColor = self.Config.Colors.Card.Unfocused.Body
		local CardShadow = self.Config.Colors.Card.Unfocused.Shadow
		
		if (Offset == 0) then 
			CardColor = self.Config.Colors.Card.Focused.Body
			CardShadow = self.Config.Colors.Card.Focused.Shadow
		end
		
		local CardOrigin = {
			(Offset+self.Config.CardsLeft)*love.graphics.getWidth()/(self.Config.CardsLeft+self.Config.CardsRight+1)+self.Config.CardMargin/2,
			self.Config.Inset.Top
		}
		local CardSize = {
			love.graphics.getWidth()/(self.Config.CardsLeft+self.Config.CardsRight+1)-self.Config.CardMargin,
			love.graphics.getHeight()-(self.Config.Inset.Top+self.Config.Inset.Bottom)
		}
		
		if Offset ~= 0 then
			CardOrigin[1] = CardOrigin[1] + self.Config.UnfocusedCardShrink
			CardOrigin[2] = CardOrigin[2] + self.Config.UnfocusedCardShrink
			CardSize[1] = CardSize[1] - self.Config.UnfocusedCardShrink*2
			CardSize[2] = CardSize[2] - self.Config.UnfocusedCardShrink*2
		end
		
		self:DrawCard(
			CardRoot, CardOrigin, CardSize,
			self.Config.Colors.Text, CardColor, CardShadow, self.Config.Colors.Card.Border,
			self.Config.ShadowOffset, self.Config.CardBorder
		)
	end
end

return Set
