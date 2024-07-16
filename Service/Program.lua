local posix = require"posix"
local luv = require"luv"
local Process = require"Moonrise.System.Posix.Process"

local OOP = require"Moonrise.OOP"

local Program = OOP.Declarator.Shortcuts(
	"LLaunch.Service.Program", {
		require"Service.Worker"
	}
)

function Program:Initialize(Instance, Name, Arguments, OnOutput, OnError, OnExit)
	Instance.Input = luv.new_pipe()
	Instance.Output = luv.new_pipe()
	Instance.Error = luv.new_pipe()
	local Handle, PID = luv.spawn(
		Name, {
			stdio={Instance.Input, Instance.Output, Instance.Error};
			args = Arguments;
		},
		function(Code, Signal)
			Instance.Output:read_stop()
			Instance.Error:read_stop()
			local Dummy = (OnExit or function() end)(Code, Signal)
		end
	)
	Instance.Handle = Handle
	Instance.PID = PID
	Instance.Output:read_start(OnOutput or function() end)
	Instance.Error:read_start(OnError or function() end)
end

local function kill_tree(parent_pid)
	-- Function to recursively kill children processes
	local function kill_recursive(pid)
		-- Get child processes of the given PID
		local ps_output = io.popen("ps -e -o pid,ppid")
		assert(ps_output)
		for line in ps_output:lines() do
			local child_pid, ppid = line:match("(%d+)%s+(%d+)")
			if tonumber(ppid) == pid then
				kill_recursive(tonumber(child_pid))
			end
		end
		ps_output:close()

		-- Kill the current process
		print("Terminating ".. pid)
		posix.kill(pid, posix.SIGTERM)
	end

	-- Start killing recursively from the parent PID
	kill_recursive(parent_pid)
end

function Program:Stop()
	kill_tree(self.PID)
end

return Program
