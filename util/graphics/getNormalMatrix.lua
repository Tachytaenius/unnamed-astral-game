local mat4 = require("lib.mathsies").mat4

local util = require("util")

return function(modelToWorld)
	local m = mat4.transpose(mat4.inverse(modelToWorld))
	return util.toMat3(m)
end
