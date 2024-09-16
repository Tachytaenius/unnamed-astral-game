local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat

local consts = require("consts")
local util = require("util")

-- a and b should be normalised
return function(a, b, i) -- Returns false if vectors are opposite and as such couldn't be rotated between
	local angle = math.acos(
		math.max(-1, math.min(1,
			vec3.dot(a, b)
		))
	)
	local crossResult = vec3.cross(a, b)
	local crossResultMagnitude = #crossResult
	if crossResultMagnitude == 0 then
		return angle > consts.tau / 2 and vec3.clone(a) or false
	end
	local axis = crossResult / crossResultMagnitude
	local axisAngleBetween = axis * angle
	local slerpQuat = quat.fromAxisAngle(axisAngleBetween * i)
	return vec3.rotate(a, slerpQuat)
end
