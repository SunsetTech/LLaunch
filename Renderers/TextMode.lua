local UITree = require"UITree"

local OOP = require"Moonrise.OOP"

local TextMode = OOP.Declarator.Shortcuts"LLaunch.Renderer.TextMode"

TextMode.Pane = OOP.Declarator.Shortcuts"LLaunch.Renderer.TextMode.Pane"

function TextMode.Pane:Initialize(Instance)
	Instance.Lines = {}
	Instance.FocusIndex = 1
end

function TextMode.Pane:CurrentLine()
	return self.Lines[#self.Lines]
end

function TextMode.Pane:Print(Contents, Color)
	local CurrentLine = self:CurrentLine()
	table.insert(CurrentLine, Color)
	table.insert(CurrentLine, Contents)
end

function TextMode.Pane:NewLine()
	table.insert(self.Lines, {})
end

function TextMode.Pane:Render(HalfHeight)
	local ColorStringPairs = {}
	local StartIndex = math.max(1,self.FocusIndex - HalfHeight)
	local EndIndex = math.min(StartIndex + HalfHeight*2, #self.Lines)
	if (EndIndex - StartIndex < HalfHeight*2) then
		StartIndex = math.max(1, EndIndex - HalfHeight*2)
	end
	for Index = StartIndex, EndIndex do
		for _, Item in pairs(self.Lines[Index]) do
			table.insert(ColorStringPairs, Item)
		end
		table.insert(ColorStringPairs,"\n")
	end
	return ColorStringPairs
end

function TextMode.Pane:MarkFocus()
	self.FocusIndex = #self.Lines
end

function TextMode:Initialize(Instance, TextColor, Oops, FocusState)
	Instance.Indent = 0
	Instance.TextColor = TextColor
	Instance.Oops = Oops
	Instance.FocusState = FocusState
	Instance.Panes = {}
end

function TextMode:Reset()
	self.Indent = 0
end

function TextMode:GetPane(Offset)
	return self.Panes[#self.Panes+(Offset or 0)]
end

function TextMode:Print(Contents, Color)
	self:GetPane():Print(Contents, Color or self.TextColor)
end

function TextMode:NewLine()
	self:GetPane():NewLine()
end

function TextMode:MarkFocus()
	self:GetPane():MarkFocus()
end

local IndentString = " "

function TextMode:Line(Prefix, Contents, Color)
	self:NewLine()
	self:Print(string.rep(IndentString,self.Indent-#Prefix) .. Prefix .. Contents, Color)
end

function TextMode:BeginPane()
	table.insert(self.Panes, TextMode.Pane())
end

function TextMode:RenderPaneToParent(HalfHeight)
	local Current = self.Panes[#self.Panes]
	local Parent = self.Panes[#self.Panes-1]
	local StartIndex = math.max(1,Current.FocusIndex - HalfHeight)
	local EndIndex = math.min(StartIndex + HalfHeight*2, #Current.Lines)
	if (EndIndex - StartIndex < HalfHeight*2) then
		StartIndex = math.max(1, EndIndex - HalfHeight*2)
	end
	local ParentIndex = #Parent.Lines
	for Index = StartIndex, EndIndex do
		if Index == Current.FocusIndex then
			Parent:MarkFocus()
		end
		local Offset = Index-StartIndex
		local CurrentIndex = ParentIndex+Offset
		Parent.Lines[CurrentIndex] = Parent.Lines[CurrentIndex] or {}
		for _, Item in pairs(Current.Lines[Index]) do
			table.insert(Parent.Lines[CurrentIndex], Item)
		end
	end
end

function TextMode:EndPane()
	table.remove(self.Panes)
end

function TextMode:Render(Element, Prefix, OverrideColor)
	Prefix = Prefix or ""
	local CurrentFocus = self.FocusState:GetFocus()
	if Element == CurrentFocus then
		self:MarkFocus()
		if Prefix == "" then
			Prefix = "> "
		else 
			Prefix = ">".. Prefix
		end
	end
	
	if OOP.Reflection.Type.Of(UITree.Input.Choice.Option, Element) then
		self:Render(Element.Key, Prefix, OverrideColor)
	elseif OOP.Reflection.Type.Of(UITree.Input.Choice, Element) then
		self:Line(Prefix, Element.Name)
		self:BeginPane()
		self.Indent = self.Indent + 4
		for Index = 1, #Element.Children do
			if Index == Element.Selected and Element == CurrentFocus then
				self:MarkFocus()
			end
			local Child = Element.Children[Index]
			self:Render(Child, Index == Element.Selected and "* " or "", Index == Element.Selected and {0,1,0} or nil)
		end
		self.Indent = self.Indent - 4
		self:GetPane(-1):NewLine()
		self:RenderPaneToParent(self.Oops.ContainerHalfHeight)
		self:EndPane()
	elseif OOP.Reflection.Type.Of(UITree.Output.Text, Element) then
		self:Line(Prefix, Element.Contents, OverrideColor or Element.Hints.Color)
	elseif OOP.Reflection.Type.Of(UITree.Input.Action, Element) then
		self:Line(Prefix, " ■  ".. Element.Name, Element.Hints.Color or OverrideColor or (Element == CurrentFocus and {0.5,0.7,1}))
	elseif OOP.Reflection.Type.Of(UITree.Input.String, Element) then
		self:Line(Prefix, Element.Name ..": ".. Element:GetValue(), Element.Hints.Color or OverrideColor or (Element == CurrentFocus and {0.5,0.7,1}))
	elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, Element) then
		self:NewLine()
		self:Print(string.rep(IndentString, self.Indent-#Prefix) .. Prefix)
		self:Print"["
		self:Print(Element:GetValue() and "●" or "●", Element:GetValue() and {0,1,0} or {1,0,0})
		self:Print("] ".. Element.Name)
	elseif OOP.Reflection.Type.Of(UITree.Output.Boolean, Element) then
		self:NewLine()
		self:Print(string.rep(IndentString, self.Indent - #Prefix) .. Prefix )
		self:Print(Element.Name ..": ")
		self:Print(Element:GetValue() and "yes" or "no", Element:GetValue() and {0,1,0} or {1,0,0})
	elseif OOP.Reflection.Type.Of(UITree.Collection, Element) then
		self:Line(Prefix, Element.Name)
		self:BeginPane()
		self.Indent = self.Indent + 4
		for Index = 1, #Element.Children do
			local Child = Element.Children[Index]
			self:Render(Child)
		end
		self.Indent = self.Indent - 4
		self:GetPane(-1):NewLine()
		self:RenderPaneToParent(self.Oops.ContainerHalfHeight)
		self:EndPane()
	end
end

return TextMode
