local FocusHandler = require"FocusHandler"
local TextMode = require"Renderers.TextMode"
local UITree = require"UITree"

local OOP = require"Moonrise.OOP"

local Modal = OOP.Declarator.Shortcuts(
	"LLaunch.Controllers.Modal", {
		require"Controllers.UITreeCollection"
	}
)

function Modal:Initialize(Instance, Root, Submit, Config, Colors, Oops)
	--Instance.Root = UITree.Collection("Modal Dialog",{},{Root})
	Instance.Root = UITree.Input.Form(
		"Cancel", UITree.Input.Form(
			Root.Name, Root, 
			function(Input)
				table.remove(Instance.Oops.DialogStack)
				return Submit(Input)
			end
		),
		function(Input)
			table.remove(Instance.Oops.DialogStack)
		end
	)
	Instance.Config = Config
	Instance.Colors = Colors
	local Focus = FocusHandler()
		Modal.Parents.UITreeCollection:Initialize(Instance, Focus, TextMode(Colors.Text, Oops, Focus), Oops)
	Instance.Focus:PushFocus(Instance.Root, 0)
	Instance.Focus:SwitchNextFocus()
end

function Modal:Draw()
	local Offset = 0
	local CardRoot = self.Root
			
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
		CardRoot, nil, nil,
		self.Config.Colors.Text, CardColor, CardShadow, self.Config.Colors.Card.Border,
		self.Config.ShadowOffset, self.Config.CardBorder
	)
end

return Modal
