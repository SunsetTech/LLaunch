local UITree = require"UITree"

local OOP = require"Moonrise.OOP"

local FocusHandler = OOP.Declarator.Shortcuts"LLaunch.FocusHandler"

FocusHandler.Stack = OOP.Declarator.Shortcuts"LLaunch.FocusHandler.Stack"

function FocusHandler.Stack:Initialize(Instance, Items)
	Instance.Items = Items or {}
end

function FocusHandler.Stack:Push(Container, Index)
	--print(Container, Index)
	assert(Index~=nil and Container~=nil and OOP.Reflection.Type.Of(UITree.Collection, Container))
	if (#self.Items > 1) then
		assert(OOP.Reflection.Type.Of(UITree.Collection, self:At(1).Container))
	end
	
	table.insert(self.Items, {Index = Index; Container = Container;})
end

function FocusHandler.Stack:Pop()
	return table.remove(self.Items)
end

function FocusHandler.Stack:Size()
	return #self.Items
end

function FocusHandler.Stack:At(Offset)
	return self.Items[self:Size()-Offset]
end

function FocusHandler.Stack:Top()
	return self:At(0)
end

function FocusHandler.Stack:Copy()
	local New = FocusHandler.Stack()
	for _, Item in pairs(self.Items) do
		New:Push(Item.Container, Item.Index)
	end
	return New
end

function FocusHandler:Initialize(Instance)
	Instance:Clear()
end

function FocusHandler:Clear()
	self.Stack = FocusHandler.Stack()
end

function FocusHandler:PushFocus(Container, Index)
	self.Stack:Push(Container, Index)
end

function FocusHandler:PopFocus()
	return self.Stack:Pop()
end

function FocusHandler:GetFocus()
	local Current = self.Stack:Top()
	return Current.Container.Children[Current.Index]
end

function FocusHandler:GetFocusParent()
	return self.Stack:At(1)
end


function FocusHandler:FindPrevFocus(IncludeCurrent)
	local NewStack = self.Stack:Copy()
	while NewStack:Size() > 0 do
		local Current = NewStack:Top()
		local SkipPop = false
		for Index = Current.Index, 1, -1 do
			Current.Index = Index
			if not (Current.Container == self.Stack:Top().Container and Current.Index == self.Stack:Top().Index) and (OOP.Reflection.Type.Of(UITree.Input.Base, Current.Container.Children[Index]) and not OOP.Reflection.Type.Of(UITree.Input.Form, Current.Container.Children[Index])) then
				print(Current.Container.Children[Index])
				return NewStack
			elseif OOP.Reflection.Type.Of(UITree.Collection, Current.Container.Children[Index]) and (not OOP.Reflection.Type.Of(UITree.Input.Base, Current.Container.Children[Index]) or OOP.Reflection.Type.Of(UITree.Input.Form, Current.Container.Children[Index])) then
				NewStack:Push(Current.Container.Children[Index], #Current.Container.Children[Index].Children)
				SkipPop = true
				break
			end
		end
		if not SkipPop then
			NewStack:Pop()
			if NewStack:Size() > 0 then
				NewStack:Top().Index = NewStack:Top().Index - 1
			end
		end
	end
end

function FocusHandler:SwitchPrevFocus(IncludeCurrent)
	self.Stack = self:FindPrevFocus(IncludeCurrent) or self.Stack
end

function FocusHandler:FindNextFocus(IncludeCurrent)
	local NewStack = self.Stack:Copy()
	while NewStack:Size() > 0 do
		local Current = NewStack:Top()
		local SkipPop = false
		for Index = Current.Index, #Current.Container.Children do
			Current.Index = Index
			if not (Current.Container == self.Stack:Top().Container and Current.Index == self.Stack:Top().Index) and (OOP.Reflection.Type.Of(UITree.Input.Base, Current.Container.Children[Index]) and not OOP.Reflection.Type.Of(UITree.Input.Form, Current.Container.Children[Index])) then
				return NewStack
			elseif OOP.Reflection.Type.Of(UITree.Collection, Current.Container.Children[Index]) and ((not OOP.Reflection.Type.Of(UITree.Input.Base, Current.Container.Children[Index])) or OOP.Reflection.Type.Of(UITree.Input.Form, Current.Container.Children[Index])) then
				NewStack:Push(Current.Container.Children[Index], 0)
				SkipPop = true
				break
			end
		end
		if not SkipPop then
			NewStack:Pop()
			if NewStack:Size() > 0 then
				NewStack:Top().Index = NewStack:Top().Index + 1
			end
		end
	end
end

function FocusHandler:SwitchNextFocus(IncludeCurrent)
	self.Stack = self:FindNextFocus(IncludeCurrent) or self.Stack
end

return FocusHandler
