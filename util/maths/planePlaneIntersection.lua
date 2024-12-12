local vec3 = require("lib.mathsies").vec3

-- Assumes directions are normalised
-- Normalises output line direction
-- Line "start" is an arbitrary point, since the planes are infinite
return function(planeADirection, planeADistance, planeBDirection, planeBDistance)
	local normalCross = vec3.cross(planeADirection, planeBDirection)
	if #normalCross == 0 then
		return nil, nil
	end
	local lineDirection = vec3.normalise(normalCross)

	local normalDot = vec3.dot(planeADirection, planeBDirection)
	local denominator = 1 - normalDot ^ 2
	local ca = (planeADistance - planeBDistance * normalDot) / denominator
	local cb = (planeBDistance - planeADistance * normalDot) / denominator
	local lineStart = ca * planeADirection + cb * planeBDirection

	return lineStart, lineDirection
end
