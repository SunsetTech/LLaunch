local OOP = require"Moonrise.OOP"

local Pool = OOP.Declarator.Shortcuts"LLaunch.Service.Pool"

function Pool:Initialize(Instance)
	Instance.Children = {}
end

function Pool:Add(Child)
	self.Children[Child] = true
end

function Pool:StopAndRemove(Child)
	assert(self.Children[Child])
	Child:Stop()
	self.Children[Child] = nil
end

function Pool:StopAndRemoveAll()
	for Child in pairs(self.Children) do
		Child:Stop()
	end
	self.Children = {}
end

return Pool
