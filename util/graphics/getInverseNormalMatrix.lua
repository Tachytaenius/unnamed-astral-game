local mat4 = require("lib.mathsies").mat4

local util = require("util")

return function(modelToWorld)
	local m = mat4.transpose(modelToWorld) -- No inversion
	return util.toMat3(m)
end
