local vec3 = require("lib.mathsies").vec3

return function(v, maxMagnitude)
	local currentMagnitude = #v
	if currentMagnitude > maxMagnitude then
		return v / currentMagnitude * maxMagnitude
	end
	return vec3.clone(v)
end
