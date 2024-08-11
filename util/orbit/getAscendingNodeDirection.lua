local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3

return function(body)
	-- Relative to parent body
	if not body.keplerOrbit then
		error("Body which is not a satellite does not have an ascending node direction")
	end
	local ascendingNodeDirection2D = vec2.fromAngle(body.keplerOrbit.longitudeOfAscendingNode)
	return vec3(ascendingNodeDirection2D.x, ascendingNodeDirection2D.y, 0)
end
