local UITree = require"UITree"

local OOP = require"Moonrise.OOP"

local Card = OOP.Declarator.Shortcuts"LLaunch.Controllers.Card"

function Card:GamepadPressed(Controller, Button)
	local CurrentFocus = self.Focus:GetFocus()
	
	if Button == "dpdown" then
		self.Focus:SwitchNextFocus()
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpup" then
		self.Focus:SwitchPrevFocus()
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpleft" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected > 1 then
		CurrentFocus.Selected = CurrentFocus.Selected - 1
		LeftHeld = true
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpright" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected < #CurrentFocus.Children then
		CurrentFocus.Selected = CurrentFocus.Selected + 1
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "b" or Button == "a" or Button == "x" or Button == "y" then
		if (OOP.Reflection.Type.Of(UITree.Input.Action, CurrentFocus)) then
			CurrentFocus:Execute()
		elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, CurrentFocus) then
			CurrentFocus:SetValue(not CurrentFocus:GetValue())
		end
	end
end

return Card
