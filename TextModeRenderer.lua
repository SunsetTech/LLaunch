local OOP = require"Moonrise.OOP"

local TextModeRenderer = OOP.Declarator.Shortcuts"LLaunch.TextModeRenderer"

function TextModeRenderer:Initialize(Instance, TextColor)
	Instance.Indent = 0
	Instance.TextStrings = {}
	Instance.TextColor = TextColor
end

function TextModeRenderer:Print(Contents, Color)
	table.insert(self.TextStrings, Color or self.TextColor)
	table.insert(self.TextStrings, Contents)
end

function TextModeRenderer:Line(Contents, Color)
	self:Print(string.rep("\t",self.Indent).. Contents .."\n", Color)
end

function TextModeRenderer:Render(Element)
	if Element == GetFocus().Element then
		Print">"
	end
	
	if OOP.Reflection.Type.Of(UITree.Collection, Element) then
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
		Line(Element.Label, Element.Hints.Color)
	elseif OOP.Reflection.Type.Of(UITree.Input.Boolean, Element) then
		Print(string.rep("\t", Indent))
		Print"["
		Print(Element:GetValue() and "●" or "●", Element:GetValue() and {0,1,0} or {1,0,0})
		Print("] ".. Element.Name .."\n")
	elseif OOP.Reflection.Type.Of(UITree.Output.Boolean, Element) then
		Print(string.rep("\t", Indent))
		Print(Element.Name ..": ")
		Print(Element:GetValue() and "yes" or "no", Element:GetValue() and {0,1,0} or {1,0,0})
		Print"\n"
	end
end

