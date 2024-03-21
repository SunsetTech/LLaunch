local lfs = require"lfs"
local http = require"coro-http-luv"
local json = require"dkjson"
local posix = require"posix"
local websocket = require"http.websocket"
local lsha2 = require"lsha2"
local mime = require"mime" --All of the above are here because of a bug in Moonrise.Import that I've been too lazy to fix
local luv = require"luv"

package.path = package.path ..";./?/init.lua"

require "Moonrise.Import.Install".All()

local Config = require"Config"
local Colors = Config.Colors
local OOP = require"Moonrise.OOP"
local UITree = require"UITree"
local FocusHandler = require"FocusHandler"
local Service = require"Service"
local Deck = require"Deck"
local TextMode = require"Renderers.TextMode"

local Oops = {
	AppExitedAt = 0;
	ContainerHalfHeight = 20;
}

local Services = Service.Pool()
local ConfigInterface = require"Interfaces.Config"(Config, Services)
local CollectionsInterface = require"Interfaces.Collections"(Config, Oops)
local ListsInterface = require"Interfaces.Lists"(Config, CollectionsInterface)
local CardFocus = require"FocusHandler"()
local RenderTarget = require"Renderers.TextMode"(Config.Colors.Text, Oops, CardFocus)

local CollectionIndex = 1
--CardFocus:SwitchFirstFocus(1, CollectionsInterface.Children[CollectionIndex])
CardFocus:PushFocus(CollectionsInterface.Children[CollectionIndex], 1)
CardFocus:SwitchNextFocus(true)

local GlobalFont
function love.load()
	math.randomseed(os.time())
    GlobalFont = love.graphics.newFont("GlobalFont.ttf",12)

    love.graphics.setFont(GlobalFont)
end

local NextTwitch = 0
local ActiveController
local UpHeld, DownHeld, LeftHeld, RightHeld = false, false, false, false
local Decks = {
	Deck(ConfigInterface);
	Deck(CollectionsInterface);
	Deck(ListsInterface);
}
local ActiveSetIndex = 2
local ActiveDeck = Decks[ActiveSetIndex]

local DialogStack = {
	
}

function love.gamepadpressed(Controller, Button)
	if love.timer.getTime() <= Oops.AppExitedAt+1/30 then return end
	
	ActiveController = Controller
	local CurrentFocus = CardFocus:GetFocus()
	if (Controller:isGamepadDown"guide") then
		if Controller:isGamepadDown"back" then
			love.event.quit(0)
		elseif Controller:isGamepadDown"start" then
			love.window.setFullscreen(not love.window.getFullscreen(),"desktop")
		elseif Controller:isGamepadDown"dpup" then

			ActiveSetIndex = math.max(ActiveSetIndex-1,1)
			ActiveDeck = Decks[ActiveSetIndex]
			CardFocus:Clear()
			CardFocus:PushFocus(ActiveDeck:GetUI(), 1)
			CardFocus:SwitchNextFocus(true)
		elseif Controller:isGamepadDown"dpdown" then
			ActiveSetIndex = math.min(ActiveSetIndex+1,#Decks)
			ActiveDeck = Decks[ActiveSetIndex]
			CardFocus:Clear()
			CardFocus:PushFocus(ActiveDeck:GetUI(), 1)
			CardFocus:SwitchNextFocus(true)
		end
	elseif Button == "leftshoulder" then
		ActiveDeck:ShiftLeft()
		CardFocus:Clear()
		CardFocus:PushFocus(ActiveDeck:GetUI(), 1)
		CardFocus:SwitchNextFocus(true)
	elseif Button == "rightshoulder" then
		ActiveDeck:ShiftRight()
		CardFocus:Clear()
		CardFocus:PushFocus(ActiveDeck:GetUI(), 1)
		CardFocus:SwitchNextFocus(true)
	elseif Button == "dpdown" then
		CardFocus:SwitchNextFocus()
		DownHeld = true
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpup" then
		CardFocus:SwitchPrevFocus()
		UpHeld = true
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpleft" and OOP.Reflection.Type.Of(UITree.Input.Choice, CardFocus:GetFocus()) and CardFocus:GetFocus().Selected > 1 then
		CardFocus:GetFocus().Selected = CardFocus:GetFocus().Selected - 1
		LeftHeld = true
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpright" and OOP.Reflection.Type.Of(UITree.Input.Choice, CardFocus:GetFocus()) and CardFocus:GetFocus().Selected < #CardFocus:GetFocus().Children then
		CardFocus:GetFocus().Selected = CardFocus:GetFocus().Selected + 1
		RightHeld = true
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "b" or Button == "a" or Button == "x" or Button == "y" then
		if (OOP.Reflection.Type.Of(UITree.Input.Action, CurrentFocus)) then
			CurrentFocus:Execute()
		elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, CurrentFocus) then
			CurrentFocus:SetValue(not CurrentFocus:GetValue())
		end
	end
end

function love.gamepadreleased(Controller, Button)
	if Button == "dpdown" then
		DownHeld = false
	elseif Button == "dpup" then
		UpHeld = false
	elseif Button == "dpleft" then
		LeftHeld = false
	elseif Button == "dpright" then
		RightHeld = false
	end
end

function love.update(dt)
	luv.run"nowait"
	if ActiveController and love.timer.getTime() >= NextTwitch then
		if UpHeld then
			CardFocus:SwitchPrevFocus()
			NextTwitch = love.timer.getTime() + 0.025
		elseif DownHeld then
			CardFocus:SwitchNextFocus()
			NextTwitch = love.timer.getTime() + 0.025
		elseif LeftHeld and OOP.Reflection.Type.Of(UITree.Input.Choice, CardFocus:GetFocus()) and CardFocus:GetFocus().Selected > 1 then
			CardFocus:GetFocus().Selected = CardFocus:GetFocus().Selected - 1
			NextTwitch = love.timer.getTime() + 0.025
		elseif RightHeld and OOP.Reflection.Type.Of(UITree.Input.Choice, CardFocus:GetFocus()) and CardFocus:GetFocus().Selected < #CardFocus:GetFocus().Children then
			CardFocus:GetFocus().Selected = CardFocus:GetFocus().Selected + 1
			NextTwitch = love.timer.getTime() + 0.025
		end
	end
end

local TextHeight = love.graphics.newText(love.graphics.getFont(),"|"):getHeight()
function love.resize(Width, Height)
	Oops.ContainerHalfHeight = math.floor(Height/TextHeight/2.5);
end

local function DrawBackground()
	love.graphics.clear(Colors.Background)
	local Divisions = math.floor((math.sin(love.timer.getTime()/5)+1)/2*100)*2+3
	local DivisionHeight = love.graphics.getHeight()/Divisions
	love.graphics.setColor(1-Colors.Background[1],1-Colors.Background[2],1-Colors.Background[3])
	for i = 1, Divisions do
		if i%2==0 then
			love.graphics.rectangle("fill",0,math.floor((i-1)*DivisionHeight),love.graphics.getWidth(),math.floor(DivisionHeight))
		end
	end
end

local function DrawTitle()
	--[[local CollectionTotal = 0
	for _, CollectionInterface in pairs(CollectionsInterface.Children) do
		CollectionTotal = CollectionTotal + #CollectionInterface.Children[2].Children
	end
	local TitleText = love.graphics.newText(love.graphics.getFont(), CollectionTotal .." games across ".. #CollectionsInterface.Children .." collections")
	love.graphics.setColor(Colors.Title)
	love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),TitleText:getHeight())
	love.graphics.setColor(Colors.Text)
	love.graphics.draw(TitleText)]]
end

local function DrawIndicator()
	if ActiveController and ActiveController:isGamepadDown"guide" then
		love.graphics.rectangle("fill", love.graphics.getWidth()-50,0,50,50)
	end
end

local function DrawCard(CardOrigin, CardSize, CardColor, ShadowColor, BorderColor, ShadowOffset, CardBorder)
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
end

local function DrawCards()
	for Offset = -Config.CardsLeft,Config.CardsRight do
		local CollectionInterface = ActiveDeck:GetUI(Offset)
		if CollectionInterface then
			RenderTarget:Clear()
			RenderTarget:Render(CollectionInterface)
			
			local TextObject = love.graphics.newText(love.graphics.getFont(),"")
			TextObject:add(RenderTarget.TextStrings,0,0)
			
			local CardColor = Colors.Card.Unfocused.Body
			local CardShadow = Colors.Card.Unfocused.Shadow
			
			if (Offset == 0) then 
				CardColor = Colors.Card.Focused.Body
				CardShadow = Colors.Card.Focused.Shadow
			end
			
			local CardOrigin = {
				(Offset+Config.CardsLeft)*love.graphics.getWidth()/(Config.CardsLeft+Config.CardsRight+1)+Config.CardMargin/2,
				Config.Inset.Top
			}
			local CardSize = {
				love.graphics.getWidth()/(Config.CardsLeft+Config.CardsRight+1)-Config.CardMargin, 
				math.min(
					TextObject:getHeight() + (Offset ~= 0 and Config.UnfocusedCardShrink*2 or 0), 
					love.graphics.getHeight()-(Config.Inset.Top+Config.Inset.Bottom)
				)
			}
			
			if Offset ~= 0 then
				CardOrigin[1] = CardOrigin[1] + Config.UnfocusedCardShrink
				CardOrigin[2] = CardOrigin[2] + Config.UnfocusedCardShrink
				CardSize[1] = CardSize[1] - Config.UnfocusedCardShrink*2
				CardSize[2] = CardSize[2] - Config.UnfocusedCardShrink*2
			end
			
			DrawCard(
				CardOrigin, CardSize,
				CardColor, CardShadow, Colors.Card.Border,
				Config.ShadowOffset, Config.CardBorder
			)
			love.graphics.setColor(Colors.Text)
			love.graphics.draw(
				TextObject,
				math.floor(CardOrigin[1]), math.floor(CardOrigin[2])
			)
		end
		
		love.graphics.setScissor()
	end
end

function love.draw()
	DrawBackground()
	DrawTitle()
	DrawCards()
	DrawIndicator()
end

function love.quit()
	Services:StopAndRemoveAll()
	print"Clean shutdown!"
end
