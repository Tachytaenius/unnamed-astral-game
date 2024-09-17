local vec3 = require("lib.mathsies").vec3

return function(vector, direction, multiplier) -- Direction should be normalised
	local parallel = direction * vec3.dot(vector, direction)
	local perpendicular = vector - parallel
	local parallelScaled = parallel * multiplier
	return parallelScaled + perpendicular
end
