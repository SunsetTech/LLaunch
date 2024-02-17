local OOP = require"Moonrise.OOP"

local UITree = OOP.Declarator.Shortcuts(
	"GUITree.UITree", {
		require"GUITree.Element"
	}
)

function UITree:Initialize(Instance, Origin, Size, Interface)
		UITree.Parents.Element:Initialize(Instance, Origin, Size)
	Instance.Interface = Interface
end

function UITree:Draw()
	local Indent = 0
	local Output = ""
	
	local function Print(Text)
		Output = Output .. Text
	end
	
	local function Line(Text)
		Print(string.rep("  ",Indent).. Text .."\n")
	end
	
	local function Render(Element)
		if Element == GetFocus().Element then
			Print">"
		end
		
		if OOP.Reflection.Type.Of(UITree.Element.Collection, Element) then
			Line(Element.Name)
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
			Line(Element.Contents)
		elseif OOP.Reflection.Type.Of(UITree.Element.Choice, Element) then
			Line(Element.Name)
			Indent = Indent + 1
			for Index, Option in pairs(Element.Options) do
				if Index == Element.Selected then
					Print"*"
				end
				Render(Option)
			end
			Indent = Indent - 1
		elseif OOP.Reflection.Type.Of(UITree.Element.Action, Element) then
			Line(Element.Label)
		end
	end

end

return UITree
