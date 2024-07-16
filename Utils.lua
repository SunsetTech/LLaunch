local posix = require"posix"

local Utils; Utils = {
	GetTime = function()
		local Time = posix.time.clock_gettime(posix.CLOCK_MONOTONIC)
		return Time.tv_sec + Time.tv_nsec/1e9
	end;

	ReadSecret = function(Path)
		local File = io.open("Secrets/".. Path, "r")
		assert(File, "File not found")
		local Secret = File:read"a":gsub("\n","")
		File:close()
		return Secret
	end;
	
	WriteSecret = function(Path, Secret)
		local File = io.open("Secrets/".. Path, "w+")
		assert(File, "File not found")
		File:write(Secret)
		File:close()
	end;
}; return Utils;
