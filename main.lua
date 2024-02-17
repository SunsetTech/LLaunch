local luv = require"luv"
local lfs = require"lfs"
package.path = package.path ..";./?/init.lua"
local Config = require"Config"
local Colors = Config.Colors
local OOP = require"Moonrise.OOP"
local UITree = require"UITree"

local AppExitedAt = 0
local CollectionTotal = 0

local CollectionElements = {
}

local ControlInterface = UITree.Element.Collection(
	"Collections", {},
	CollectionElements
)

for _, Collection in pairs(Config.Collections) do
	local LauncherOptions = {}
	for _, LauncherName in pairs(Collection.Launchers) do
		table.insert(
			LauncherOptions,
			UITree.Element.Text("Launcher Name", {}, Config.Launchers[LauncherName].Label)
		)
	end
	local LauncherSelect = UITree.Element.Choice("Collection Launcher",{},LauncherOptions)
	
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
						UITree.Element.Action(
							File, {},
							File,
							function()
								love.window.setFullscreen(false)
								Config.Launchers[Collection.Launchers[LauncherSelect.Selected]].Launch(Fullpath)
								love.window.setFullscreen(true, "desktop")
								AppExitedAt = os.time()
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
		CollectionElements, UITree.Element.Collection(
			Collection.Label, {},
			{
				LauncherSelect,
				UITree.Element.Collection(
					"Games", {},
					CollectionGames
				)
			}
		)
	)
end

FocusStack = {}

local function PushFocus(Index, Element)
	table.insert(
		FocusStack, {
			Element = Element;
			Index = Index;
		}
	)
end

local function PopFocus()
	return table.remove(FocusStack)
end

local function GetFocus()
	return FocusStack[#FocusStack]
end

local function GetFocusParent()
	return FocusStack[#FocusStack-1]
end

local function FindFirstFocus(Index, Element)
	PushFocus(Index, Element)
	if OOP.Reflection.Type.Of(UITree.Element.Collection, Element) then
		FindFirstFocus(1, Element.Children[1])
	end
end

local function FindLastFocus(Index, Element)
	PushFocus(Index, Element)
	if OOP.Reflection.Type.Of(UITree.Element.Collection, Element) then
		FindLastFocus(#Element.Children, Element.Children[#Element.Children])
	end
end

local function FindPrevFocus()
	local Current = PopFocus()
	local Parent = GetFocus()
	if Current.Index == 1 then
		if #FocusStack == 1 then
			FindFirstFocus(Current.Index, Current.Element) --kind of inefficient to do this but it was easy to write
		else
			FindPrevFocus()
		end
	else
		local Index = Current.Index - 1
		local NewFocus = Parent.Element.Children[Index]
		if OOP.Reflection.Type.Of(UITree.Element.Collection, NewFocus) then
			FindLastFocus(Index, NewFocus)
		else
			PushFocus(Index, NewFocus)
		end
	end
end

local function FindNextFocus()
	local Current = PopFocus()
	local Parent = GetFocus()
	if Current.Index == #Parent.Element.Children then
		if #FocusStack == 1 then
			FindLastFocus(Current.Index, Current.Element)
		else
			FindNextFocus()
		end
	else
		local Index = Current.Index + 1
		local NewFocus = Parent.Element.Children[Index]
		if OOP.Reflection.Type.Of(UITree.Element.Collection, NewFocus) then
			FindFirstFocus(Index, NewFocus)
		else
			PushFocus(Index, NewFocus)
		end
	end
end

local CollectionIndex = 1
FindFirstFocus(1, ControlInterface.Children[CollectionIndex])

function love.load()
	love.window.setMode(800,600,{display=2})
	love.window.setFullscreen(true, "desktop")
end

local NextTwitch = 0
local ActiveController
function love.gamepadpressed(Controller, Button)
	ActiveController = Controller
	local CurrentFocus = GetFocus().Element
	if os.time() == AppExitedAt then return end
	if (Controller:isGamepadDown"guide") then
		if Controller:isGamepadDown"back" then
			os.exit(0)
		elseif Controller:isGamepadDown"start" then
			love.window.setFullscreen(not love.window.getFullscreen(),"desktop")
		end
	elseif Button == "leftshoulder" then
		CollectionIndex = (CollectionIndex-2)%#ControlInterface.Children+1
		local Collection = ControlInterface.Children[CollectionIndex]
		FocusStack = {}
		FindFirstFocus(1, Collection)
		--SelectionIndex = 1
	elseif Button == "rightshoulder" then
		CollectionIndex = CollectionIndex%#ControlInterface.Children+1
		local Collection = ControlInterface.Children[CollectionIndex]
		FocusStack = {}
		FindFirstFocus(1, Collection)
		--SelectionIndex = 1
	elseif Button == "dpdown" then
		FindNextFocus()
		--SelectionIndex = SelectionIndex + 1
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpup" then
		FindPrevFocus()
		--SelectionIndex = SelectionIndex - 1
		NextTwitch = love.timer.getTime() + 0.25
	elseif Button == "dpleft" and OOP.Reflection.Type.Of(UITree.Element.Choice, CurrentFocus) and CurrentFocus.Selected > 1 then
		CurrentFocus.Selected = CurrentFocus.Selected - 1
	elseif Button == "dpright" and OOP.Reflection.Type.Of(UITree.Element.Choice, CurrentFocus) and CurrentFocus.Selected < #CurrentFocus.Options then
		CurrentFocus.Selected = CurrentFocus.Selected + 1
	elseif Button == "b" or Button == "a" or Button == "x" or Button == "y" then
		if (OOP.Reflection.Type.Of(UITree.Element.Action, CurrentFocus)) then
			CurrentFocus:Execute()
		end
	end
end

function love.update()
	luv.run"nowait"
	if ActiveController and love.timer.getTime() >= NextTwitch then
		if ActiveController:isGamepadDown"dpup" then
			FindPrevFocus()
			NextTwitch = love.timer.getTime() + 0.025
		elseif ActiveController:isGamepadDown"dpdown" then
			FindNextFocus()
			NextTwitch = love.timer.getTime() + 0.025
		end
	end
end

local ContainerHalfHeight = 40

local TextHeight = love.graphics.newText(love.graphics.getFont(),"|"):getHeight()
function love.resize(Width, Height)
	ContainerHalfHeight = math.floor(Height/TextHeight/2)
end

function love.draw()
	local Indent = 0
	local TextStrings
	local function Print(Contents, Color)
		table.insert(TextStrings, Color or Colors.Text)
		table.insert(TextStrings, Contents)
	end
	
	local function Line(Contents, Color)
		Print(string.rep("  ",Indent).. Contents .."\n", Color)
	end
	
	local function Render(Element)
		if Element == GetFocus().Element then
			Print">"
		end
		
		if OOP.Reflection.Type.Of(UITree.Element.Collection, Element) then
			Line(Element.Name, Element.Hints.Color)
			Indent = Indent + 1
			
			local StartIndex, EndIndex
			if GetFocusParent().Element == Element then
				StartIndex = math.max(1,GetFocus().Index - ContainerHalfHeight)
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
		elseif OOP.Reflection.Type.Of(UITree.Element.Text, Element) then
			Line(Element.Contents, Element.Hints.Color)
		elseif OOP.Reflection.Type.Of(UITree.Element.Choice, Element) then
			Line(Element.Name, Element.Hints.Color)
			Indent = Indent + 1
			for Index, Option in pairs(Element.Options) do
				if Index == Element.Selected then
					Print"*"
				end
				Render(Option)
			end
			Indent = Indent - 1
		elseif OOP.Reflection.Type.Of(UITree.Element.Action, Element) then
			Line(Element.Label, Element.Hints.Color)
		end
	end
	local CollectionTotal = 0
	for _, CollectionInterface in pairs(ControlInterface.Children) do
		CollectionTotal = CollectionTotal + #CollectionInterface.Children[2].Children
	end
	local TitleText = love.graphics.newText(love.graphics.getFont(), CollectionTotal .." games across ".. #ControlInterface.Children .." collections")
	love.graphics.clear(Colors.Background)
	love.graphics.setScissor(0,0,love.graphics.getWidth(),TitleText:getHeight())
	love.graphics.clear(Colors.Title)
	love.graphics.setColor(Colors.Text)
	love.graphics.draw(TitleText)
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
		local ShadowOrigin = {
			CardOrigin[1]-Config.ShadowOffset,
			CardOrigin[2]-Config.ShadowOffset
		}
		local BorderOrigin = {
			CardOrigin[1]-Config.CardBorder,
			CardOrigin[2]-Config.CardBorder
		}
		local BorderSize = {
			CardSize[1]+Config.CardBorder*2,
			CardSize[2]+Config.CardBorder*2
		}
		love.graphics.setScissor(
			ShadowOrigin[1], ShadowOrigin[2],
			CardSize[1], CardSize[2]
		)
		love.graphics.clear(CardShadow)
		love.graphics.setScissor(
			BorderOrigin[1], BorderOrigin[2],
			BorderSize[1], BorderSize[2]
		)
		love.graphics.clear(Colors.Card.Border)
		love.graphics.setScissor(
			CardOrigin[1], CardOrigin[2],
			CardSize[1], CardSize[2]
		)
		love.graphics.clear(CardColor)
		TextStrings = {}
		local CollectionInterface = ControlInterface.Children[(CollectionIndex-1+Offset)%(#ControlInterface.Children)+1]
		if CollectionInterface then
			Render(CollectionInterface)
			local TextObject = love.graphics.newText(love.graphics.getFont(),"")
			TextObject:add(TextStrings,0,0)
			love.graphics.draw(
				TextObject,
				math.floor(CardOrigin[1]), math.floor(CardOrigin[2])
			)
		end
		love.graphics.setScissor()
	end
end
