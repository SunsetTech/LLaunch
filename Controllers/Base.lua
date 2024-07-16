local OOP = require"Moonrise.OOP"

local Base = OOP.Declarator.Shortcuts"LLaunch.Controllers.Base"

function Base:KeyPressed(Key, ScanCode, IsRepeat) end
function Base:KeyReleased(Key, ScanCode) end
function Base:TextInput(Text) end
function Base:MousePressed(X, Y, Button, Count) end
function Base:MouseMoved(X, Y) end
function Base:MouseReleased(X, Y, Button) end
function Base:WheelMoved(DeltaX, DeltaY) end
function Base:GamepadPressed(Controller, Button) end
function Base:GamepadReleased(Controller, Button) end
function Base:Update(Delta) end
function Base:Draw() end

return Base
