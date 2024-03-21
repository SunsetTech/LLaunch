local UITree = require"UITree"

local OOP = require"Moonrise.OOP"

local TextMode = OOP.Declarator.Shortcuts"LLaunch.Renderer.TextMode"

function TextMode:Initialize(Instance, TextColor, Oops, FocusState)
	Instance.Indent = 0
	Instance.TextStrings = {}
	Instance.TextColor = TextColor
	Instance.Oops = Oops
	Instance.FocusState = FocusState
end

function TextMode:Clear()
	self.TextStrings = {}
	self.Indent = 0
end

function TextMode:Print(Contents, Color)
	table.insert(self.TextStrings, Color or self.TextColor)
	table.insert(self.TextStrings, Contents)
end

local IndentString = " "

function TextMode:Line(Prefix, Contents, Color)
	self:Print(string.rep(IndentString,self.Indent-#Prefix) .. Prefix .. Contents .."\n", Color)
end

function TextMode:Render(Element, Prefix, OverrideColor)
	Prefix = Prefix or " "
	local CurrentFocus = self.FocusState:GetFocus()
	if Element == CurrentFocus then
		Prefix = ">"..Prefix
	end
	
	if OOP.Reflection.Type.Of(UITree.Input.Choice.Option, Element) then
		self:Render(Element.Display, Prefix, OverrideColor)
	elseif OOP.Reflection.Type.Of(UITree.Input.Choice, Element) then
		self:Line(Prefix, Element.Name, Element.Hints.Color or OverrideColor or (Element == CurrentFocus and {0.5,0.7,1}))
		self.Indent = self.Indent + 2
		
		local StartIndex = math.max(1,Element.Selected - self.Oops.ContainerHalfHeight) --
		local EndIndex = math.min(StartIndex + self.Oops.ContainerHalfHeight*2, #Element.Children)
		if (EndIndex - StartIndex < self.Oops.ContainerHalfHeight*2) then
			StartIndex = EndIndex - self.Oops.ContainerHalfHeight*2
		end

		for Index = StartIndex, EndIndex do
			local Child = Element.Children[Index]
			--[[if Index == Element.Selected then
				self:Print"*" 
			end]]
			self:Render(Child, Index == Element.Selected and "* " or "", Index == Element.Selected and {0,1,0} or nil)
		end

		self.Indent = self.Indent - 2
	elseif OOP.Reflection.Type.Of(UITree.Output.Text, Element) then
		self:Line(Prefix, Element.Contents, OverrideColor or Element.Hints.Color)
	elseif OOP.Reflection.Type.Of(UITree.Input.Action, Element) then
		self:Line(Prefix, " ■  ".. Element.Label, Element.Hints.Color or OverrideColor or (Element == CurrentFocus and {0.5,0.7,1}))
	elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, Element) then
		self:Print(string.rep(IndentString, self.Indent-#Prefix) .. Prefix)
		self:Print"["
		self:Print(Element:GetValue() and "●" or "●", Element:GetValue() and {0,1,0} or {1,0,0})
		self:Print("] ".. Element.Name .."\n")
	elseif OOP.Reflection.Type.Of(UITree.Output.Boolean, Element) then
		self:Print(string.rep(IndentString, self.Indent - #Prefix) .. Prefix )
		self:Print(Element.Name ..": ")
		self:Print(Element:GetValue() and "yes" or "no", Element:GetValue() and {0,1,0} or {1,0,0})
		self:Print"\n"
	elseif OOP.Reflection.Type.Of(UITree.Collection, Element) then
		self:Line(Prefix, Element.Name, Element.Hints.Color)
		self.Indent = self.Indent + 2
		
		local StartIndex, EndIndex
		if self.FocusState:GetFocusParent() == Element then
			StartIndex = math.max(1,self.FocusState:GetFocus().Index - self.Oops.ContainerHalfHeight)
			EndIndex = math.min(StartIndex + self.Oops.ContainerHalfHeight*2, #Element.Children)
		else
			StartIndex = 1
			EndIndex = math.min(StartIndex + self.Oops.ContainerHalfHeight*2, #Element.Children)
		end
		
		for Index = StartIndex, EndIndex do
			local Child = Element.Children[Index]
			self:Render(Child)
		end
		
		self.Indent = self.Indent - 2
	end
end

return TextMode
