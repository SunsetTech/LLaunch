local luv = require"luv"
local sqlite3 = require"lsqlite3"

package.path = package.path ..";./?/init.lua"

local UITree = require"UITree"

local Config = require"Config.Launcher"
local Colors = Config.Colors
local Service = require"Service"
local Set = require"Controllers.Set"

local Database = sqlite3.open"Data/Launcher.db"

Database:exec[[
	CREATE TABLE IF NOT EXISTS ListEntries (
		List TEXT,
		Collection TEXT,
		Name TEXT,
		Identifier TEXT
	);
]]

local Oops = {
	AppExitedAt = 0;
	ContainerHalfHeight = 20;
	Database = Database;
}

local Services = Service.Pool()

local Decks = UITree.Collection"Decks"
Oops.Decks = Decks

local ConfigInterface = require"Interfaces.Config"(Config, Services, Oops)
Decks:Add(ConfigInterface)
local ListsInterface, Lists = require"Interfaces.Lists"(Config, Oops)
Decks:Add(ListsInterface)
Oops.Lists = Lists
Oops.ListsInterface = ListsInterface
local CollectionsInterface = require"Interfaces.Collections"(Config, Oops)
Decks:Add(CollectionsInterface)

local GlobalFont
local TextHeight

local function CalculateHalfHeight(Height)
	return math.floor((Height-(Config.Inset.Top+Config.Inset.Bottom+10))/TextHeight/2)
end

function love.load()
	math.randomseed(os.time())
	GlobalFont = love.graphics.newFont("Assets/GlobalFont.ttf",12)
	Oops.DefaultFont = love.graphics.getFont()
	love.graphics.setFont(GlobalFont)
	TextHeight = love.graphics.newText(love.graphics.getFont(),"|"):getHeight()
	Oops.ContainerHalfHeight = CalculateHalfHeight(love.graphics.getHeight())
end

local ActiveController
Oops.DialogStack = {};
table.insert(
	Oops.DialogStack,
	Set(
		{
			Set.Deck(ConfigInterface);
			Set.Deck(CollectionsInterface);
			Set.Deck(ListsInterface);
		},
		2,
		Config,
		Config.Colors,
		Oops
	)
)

love.keyboard.setKeyRepeat(true)

function love.keypressed(key, scancode, isRepeat)
	Oops.DialogStack[#Oops.DialogStack]:KeyPressed(key, scancode, isRepeat)
end

function love.keyreleased(key, scancode)
	Oops.DialogStack[#Oops.DialogStack]:KeyReleased(key, scancode)
end

function love.textinput(text)
	Oops.DialogStack[#Oops.DialogStack]:TextInput(text)
end

function love.mousepressed(mx, my, mbutton, pressCount)
	Oops.DialogStack[#Oops.DialogStack]:MousePressed(mx, my, mbutton, pressCount)
end
function love.mousemoved(mx, my)
	Oops.DialogStack[#Oops.DialogStack]:MouseMoved(mx, my)
end
function love.mousereleased(mx, my, mbutton)
	Oops.DialogStack[#Oops.DialogStack]:MouseReleased(mx, my, mbutton)
end
function love.wheelmoved(dx, dy)
	Oops.DialogStack[#Oops.DialogStack]:WheelMoved(dx, dy)
end
function love.gamepadpressed(Controller, Button)
	if love.timer.getTime() <= Oops.AppExitedAt+1/30 then return end
	
	if Controller:isGamepadDown"guide" then
		if Controller:isGamepadDown"back" then
			love.event.quit(0)
		elseif Controller:isGamepadDown"start" then
			love.window.setFullscreen(not(love.window.getFullscreen()),"desktop")
		else
			Oops.DialogStack[#Oops.DialogStack]:GamepadPressed(Controller, Button)
		end
	else
		Oops.DialogStack[#Oops.DialogStack]:GamepadPressed(Controller, Button)
	end
end

function love.gamepadreleased(Controller, Button)
	Oops.DialogStack[#Oops.DialogStack]:GamepadReleased(Controller, Button)
end

function love.update(Delta)
	luv.run"nowait"
	Oops.DialogStack[#Oops.DialogStack]:Update(Delta)
end

function love.resize(Width, Height)
	Oops.ContainerHalfHeight = CalculateHalfHeight(Height)
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

local function DrawIndicator()
	if ActiveController and ActiveController:isGamepadDown"guide" then
		love.graphics.rectangle("fill", love.graphics.getWidth()-50,0,50,50)
	end
end

function love.draw()
	DrawBackground()
	for _, Dialog in pairs(Oops.DialogStack) do
		Dialog:Draw()
	end
	DrawIndicator()
end

function love.quit()
	Services:StopAndRemoveAll()
	print"Clean shutdown!"
end
