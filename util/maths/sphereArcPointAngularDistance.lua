local vec3 = require("lib.mathsies").vec3
local util = require("util")

-- Assumes all vectors are normalised
return function(arcStart, arcEnd, point)
	-- Get closest point on the great circle made by arcStart and arcEnd
	local p = vec3.cross(arcStart, arcEnd)
	if #p == 0 then
		return nil
	end
	local q = vec3.cross(point, p)
	if #q == 0 then
		return nil
	end
	local closestGreatCirclePointPreNormalise = vec3.cross(p, q)
	if #closestGreatCirclePointPreNormalise == 0 then
		return nil
	end
	local closestGreatCirclePoint = vec3.normalise(closestGreatCirclePointPreNormalise)

	-- See whether closestGreatCirclePoint should be cropped to arcStart/arcEnd
	local arcAngle = util.angleBetweenDirections(arcStart, arcEnd)
	local startAngle = util.angleBetweenDirections(closestGreatCirclePoint, arcStart)
	local endAngle = util.angleBetweenDirections(closestGreatCirclePoint, arcEnd)
	local arcClosestPoint
	if startAngle <= arcAngle and endAngle <= arcAngle then
		arcClosestPoint = closestGreatCirclePoint
	else
		arcClosestPoint = startAngle < endAngle and arcStart or arcEnd
	end

	-- Get distance
	return util.angleBetweenDirections(point, arcClosestPoint)
	-- If this function is converted to a "get closest point on arc" function rather than one that calculates its distance, then remember to use vec3.clone since the output could be one of the arguments
end
