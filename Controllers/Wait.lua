local OOP = require"Moonrise.OOP"

---@class LLaunch.Controllers.Wait
---@overload fun(Routine: thread, Label: string, DialogStack: table): LLaunch.Controllers.Wait
---@field StartTime number
---@field Label string
---@field Routine thread
---@field DialogStack table
local Wait = OOP.Declarator.Shortcuts(
	"LLaunch.Controllers.Wait", {
		require"Controllers.Base"
	}
)

function Wait:Initialize(Instance, Routine, Label, DialogStack)
	Instance.Routine = Routine
	Instance.DialogStack = DialogStack
	Instance.StartTime = love.timer.getTime()
	Instance.Label = Label
end

function Wait:Update()
	if coroutine.status(self.Routine) == "dead" then
		table.remove(self.DialogStack)
	else
		coroutine.resume(self.Routine)
	end
end

function Wait:KeyPressed(Key)
	if Key == "f" and (love.keyboard.isDown"lctrl" or love.keyboard.isDown"rctrl") then
		table.remove(self.DialogStack)
	end
end

function Wait:Draw()
	local WaitingText = love.graphics.newText(love.graphics.getFont(), ("%s..."):format(self.Label))
	local TextWidth = WaitingText:getWidth()
	local TextHeight = WaitingText:getHeight()
	local OriginX = math.floor(love.graphics.getWidth()/2-TextWidth/2)
	local OriginY = math.floor(love.graphics.getHeight()/2-TextHeight/2)
	love.graphics.setColor(0,0,0,0.5)
	love.graphics.rectangle("fill", OriginX, OriginY,TextWidth,TextHeight)
	love.graphics.setColor(1,1,1,1)
	local AnimationStep = math.floor(((love.timer.getTime()-self.StartTime)*2)%4)
	love.graphics.print(self.Label .. string.rep(".", AnimationStep), OriginX, OriginY)
end

return Wait
