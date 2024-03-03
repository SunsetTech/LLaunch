local luv = require"luv"
local lfs = require"lfs"
local http = require"coro-http-luv"
local json = require"dkjson"
local posix = require"posix"
local websocket = require"http.websocket"
local lsha2 = require"lsha2"
local mime = require"mime"
io.popen[[lua ProcessSocket.lua "asld asdildasl askldask"]]
package.path = package.path ..";./?/init.lua"
require "Moonrise.Import.Install".All()
local Config = require"Config"
local Colors = Config.Colors
local OOP = require"Moonrise.OOP"
local UITree = require"UITree"
local FocusHandler = require"FocusHandler"
local Service = require"Service"
local CardSet = require"CardSet"

local Services = Service.Pool()
local ConfigInterface = require"Interfaces.Config"(Config, Services)

local AppExitedAt = 0
local CollectionTotal = 0

local CollectionElements = {--[[ServicesInterface]]}

local ControlInterface = UITree.Collection(
	"Collections", {},
	CollectionElements
)

for _, Collection in pairs(Config.Collections) do
	local LauncherOptions = {}
	for _, LauncherName in pairs(Collection.Launchers) do
		table.insert(
			LauncherOptions,
			UITree.Output.Text("Launcher Name", {}, Config.Launchers[LauncherName].Label)
		)
	end
	local LauncherSelect = UITree.Input.Choice("Collection Launcher",{},LauncherOptions)
	
	local CollectionGames = {}
	
	if Collection.Scan then
		CollectionGames, SubTotal = Collection.Scan(Collection)
		--CollectionTotal = CollectionTotal + SubTotal
	else
		for _, Path in pairs(Collection.Paths) do
			for File in lfs.dir(Path) do
				if (File ~= "." and File ~= "..") then
					local Fullpath = Path .."/".. File
					CollectionTotal = CollectionTotal + 1
					table.insert(
						CollectionGames, 
						UITree.Input.Action(
							File, {},
							File,
							function()
								love.window.setFullscreen(false)
								Config.Launchers[Collection.Launchers[LauncherSelect.Selected]].Launch(Fullpath)
								love.window.setFullscreen(true, "desktop")
								AppExitedAt = love.timer.getTime()
							end
						)
					)
				end
			end
		end
	end
	table.sort(
		CollectionGames, function(Left, Right)
			return Left.Name < Right.Name
		end
	)
	table.insert(
		CollectionElements, UITree.Collection(
			Collection.Label, {},
			{
				LauncherSelect,
				UITree.Collection(
					"Games", {},
					CollectionGames
				)
			}
		)
	)
end

local CardFocus = FocusHandler()
local CollectionIndex = 1
CardFocus:FindFirstFocus(1, ControlInterface.Children[CollectionIndex])

local GlobalFont
function love.load()
	math.randomseed(os.time())
    GlobalFont = love.graphics.newFont("GlobalFont.ttf",12)

    love.graphics.setFont(GlobalFont)
end

local NextTwitch = 0
local ActiveController
local UpHeld, DownHeld = false, false
local CollectionsCardSet = CardSet(ControlInterface)
local ConfigCardSet = CardSet(ConfigInterface)
local ActiveCardSet = CollectionsCardSet

function love.gamepadpressed(Controller, Button)
	if love.timer.getTime() <= AppExitedAt+1 then return end
	
	ActiveController = Controller
	local CurrentFocus = CardFocus:GetFocus().Element
	if (Controller:isGamepadDown"guide") then
		if Controller:isGamepadDown"back" then
			love.event.quit(0)
		elseif Controller:isGamepadDown"start" then
			love.window.setFullscreen(not love.window.getFullscreen(),"desktop")
		elseif Controller:isGamepadDown"dpup" then
			ActiveCardSet = ConfigCardSet
			CardFocus:Clear()
			CardFocus:FindFirstFocus(1, ActiveCardSet:GetUI())
		elseif Controller:isGamepadDown"dpdown" then
			ActiveCardSet = CollectionsCardSet
			CardFocus:Clear()
			CardFocus:FindFirstFocus(1, ActiveCardSet:GetUI())
		end
	elseif Button == "leftshoulder" then
		ActiveCardSet:ShiftLeft()
		CardFocus:Clear()
		CardFocus:FindFirstFocus(1, ActiveCardSet:GetUI())
	elseif Button == "rightshoulder" then
		ActiveCardSet:ShiftRight()
		CardFocus:Clear()
		CardFocus:FindFirstFocus(1, ActiveCardSet:GetUI())
	elseif Button == "dpdown" then
		CardFocus:FindNextFocus()
		DownHeld = true
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpup" then
		CardFocus:FindPrevFocus()
		UpHeld = true
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpleft" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected > 1 then
		CurrentFocus.Selected = CurrentFocus.Selected - 1
	elseif Button == "dpright" and OOP.Reflection.Type.Of(UITree.Input.Choice, CurrentFocus) and CurrentFocus.Selected < #CurrentFocus.Options then
		CurrentFocus.Selected = CurrentFocus.Selected + 1
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
	end
end

function love.update(dt)
	--print(love.timer.getTime())
	luv.run"nowait"
	if ActiveController and love.timer.getTime() >= NextTwitch then
		if UpHeld then
			CardFocus:FindPrevFocus()
			NextTwitch = love.timer.getTime() + 0.025
		elseif DownHeld then
			CardFocus:FindNextFocus()
			NextTwitch = love.timer.getTime() + 0.025
		end
	end
end

local ContainerHalfHeight = 40

local TextHeight = love.graphics.newText(love.graphics.getFont(),"|"):getHeight()
function love.resize(Width, Height)
	ContainerHalfHeight = math.floor(Height/TextHeight/2)
end

local function RenderCard(CardOrigin, CardSize, CardColor, ShadowColor, BorderColor, ShadowOffset, CardBorder)
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

local IndentString = "  "
function love.draw()
	local Indent = 0
	local TextStrings
	local function Print(Contents, Color)
		table.insert(TextStrings, Color or Colors.Text)
		table.insert(TextStrings, Contents)
	end
	
	local function Line(Contents, Color)
		Print(string.rep(IndentString,Indent).. Contents .."\n", Color)
	end
	
	local function Render(Element)
		if Element == CardFocus:GetFocus().Element then
			Print">"
		end
		
		if OOP.Reflection.Type.Of(UITree.Collection, Element) then
			Line(Element.Name, Element.Hints.Color)
			Indent = Indent + 1
			
			local StartIndex, EndIndex
			if CardFocus:GetFocusParent().Element == Element then
				StartIndex = math.max(1,CardFocus:GetFocus().Index - ContainerHalfHeight)
				EndIndex = math.min(StartIndex + ContainerHalfHeight*2, #Element.Children)
			else
				StartIndex = 1
				EndIndex = math.min(StartIndex + ContainerHalfHeight*2, #Element.Children)
			end
			
			for Index = StartIndex, EndIndex do
				local Child = Element.Children[Index]
				Render(Child)
			end
			
			Indent = Indent - 1
		elseif OOP.Reflection.Type.Of(UITree.Output.Text, Element) then
			Line(Element.Contents, Element.Hints.Color)
		elseif OOP.Reflection.Type.Of(UITree.Input.Choice, Element) then
			Line(Element.Name, Element.Hints.Color)
			Indent = Indent + 1
			for Index, Option in pairs(Element.Options) do
				if Index == Element.Selected then
					Print"*"
				end
				Render(Option)
			end
			Indent = Indent - 1
		elseif OOP.Reflection.Type.Of(UITree.Input.Action, Element) then
			Line(" ■  ".. Element.Label, Element.Hints.Color)
		elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, Element) then
			Print(string.rep(IndentString, Indent))
			Print"("
			Print(Element:GetValue() and "●" or " ", Element:GetValue() and {0,1,0} or {1,0,0})
			Print(") ".. Element.Name .."\n")
		elseif OOP.Reflection.Type.Of(UITree.Output.Boolean, Element) then
			Print(string.rep(IndentString, Indent))
			Print(Element.Name ..": ")
			Print(Element:GetValue() and "yes" or "no", Element:GetValue() and {0,1,0} or {1,0,0})
			Print"\n"
		end
	end
	local CollectionTotal = 0
	for _, CollectionInterface in pairs(ControlInterface.Children) do
		CollectionTotal = CollectionTotal + #CollectionInterface.Children[2].Children
	end
	local TitleText = love.graphics.newText(love.graphics.getFont(), CollectionTotal .." games across ".. #ControlInterface.Children .." collections")
	love.graphics.clear(Colors.Background)
	local Divisions = math.floor((math.sin(love.timer.getTime()/5)+1)/2*100)*2+3
	local DivisionHeight = love.graphics.getHeight()/Divisions
	love.graphics.setColor(1-Colors.Background[1],1-Colors.Background[2],1-Colors.Background[3])
	for i = 1, Divisions do
		if i%2==0 then
			love.graphics.rectangle("fill",0,math.floor((i-1)*DivisionHeight),love.graphics.getWidth(),math.floor(DivisionHeight))
		end
	end
	--love.graphics.setScissor(0,0,love.graphics.getWidth(),TitleText:getHeight())
	love.graphics.setColor(Colors.Title)
	love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),TitleText:getHeight())
	love.graphics.setColor(Colors.Text)
	love.graphics.draw(TitleText)
	if ActiveController and ActiveController:isGamepadDown"guide" then
		love.graphics.rectangle("fill", love.graphics.getWidth()-50,0,50,50)
	end
	for Offset = -Config.CardsLeft,Config.CardsRight do
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
			love.graphics.getHeight()-(Config.Inset.Top+Config.Inset.Bottom)
		}
		if Offset ~= 0 then
			CardOrigin[1] = CardOrigin[1] + Config.UnfocusedCardShrink
			CardOrigin[2] = CardOrigin[2] + Config.UnfocusedCardShrink
			CardSize[1] = CardSize[1] - Config.UnfocusedCardShrink*2
			CardSize[2] = CardSize[2] - Config.UnfocusedCardShrink*2
		end
		RenderCard(
			CardOrigin, CardSize,
			CardColor, CardShadow, Colors.Card.Border,
			Config.ShadowOffset, Config.CardBorder
		)
		TextStrings = {}
		local CollectionInterface = ActiveCardSet:GetUI(Offset)
		if CollectionInterface then
			--Line(#CollectionInterface.Children[2].Children .." games")
			--Line""
			Render(CollectionInterface)
			local TextObject = love.graphics.newText(love.graphics.getFont(),"")
			TextObject:add(TextStrings,0,0)
			love.graphics.setColor(Colors.Text)
			love.graphics.draw(
				TextObject,
				math.floor(CardOrigin[1]), math.floor(CardOrigin[2])
			)
		end
		love.graphics.setScissor()
	end
end

function love.quit()
	print"Goodbye"
	Services:StopAndRemoveAll()
end
