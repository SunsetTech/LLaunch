local UITree = require"UITree"

local OOP = require"Moonrise.OOP"

local FocusHandler = OOP.Declarator.Shortcuts"LLaunch.FocusHandler"

function FocusHandler:Initialize(Instance)
	Instance:Clear()
end

function FocusHandler:Clear()
	self.Stack = {}
end

function FocusHandler:PushFocus(Index, Element)
	assert(Index~=nil and Element~=nil)
	if (#self.Stack > 0) then
		assert(OOP.Reflection.Type.Of(UITree.Collection, self:GetFocus().Element))
	end
	table.insert(
		self.Stack, {
			Element = Element;
			Index = Index;
		}
	)
end

function FocusHandler:PopFocus()
	return table.remove(self.Stack)
end

function FocusHandler:GetFocus()
	return self.Stack[#self.Stack]
end

function FocusHandler:GetFocusParent()
	return self.Stack[#self.Stack-1]
end

function FocusHandler:FindFirstFocus(Index, Element)
	self:PushFocus(Index, Element)
	if OOP.Reflection.Type.Of(UITree.Collection, Element) then
		self:FindFirstFocus(1, Element.Children[1])
	end
end

function FocusHandler:FindLastFocus(Index, Element)
	self:PushFocus(Index, Element)
	if OOP.Reflection.Type.Of(UITree.Collection, Element) then
		self:FindLastFocus(#Element.Children, Element.Children[#Element.Children])
	end
end

function FocusHandler:FindPrevFocus()
	local Current = self:PopFocus()
	local Parent = self:GetFocus()
	if Current.Index == 1 then
		if #self.Stack == 1 then
			self:FindFirstFocus(Current.Index, Current.Element) --kind of inefficient to do this but it was easy to write
		else
			self:FindPrevFocus()
		end
	else
		local Index = Current.Index - 1
		local NewFocus = Parent.Element.Children[Index]
		if OOP.Reflection.Type.Of(UITree.Collection, NewFocus) then
			self:FindLastFocus(Index, NewFocus)
		else
			self:PushFocus(Index, NewFocus)
		end
	end
end

function FocusHandler:FindNextFocus()
	local Current = self:PopFocus()
	local Parent = self:GetFocus()
	if Current.Index == #Parent.Element.Children then
		if #self.Stack == 1 then
			self:FindLastFocus(Current.Index, Current.Element)
		else
			self:FindNextFocus()
		end
	else
		local Index = Current.Index + 1
		local NewFocus = Parent.Element.Children[Index]
		if OOP.Reflection.Type.Of(UITree.Collection, NewFocus) then
			self:FindFirstFocus(Index, NewFocus)
		else
			self:PushFocus(Index, NewFocus)
		end
	end
end

return FocusHandler
