local util = require("util")

local vec3 = require("lib.mathsies").vec3

-- Assumes shortest possible arcs
-- Assumes all vectors are normalised
-- Returns point of intersection (or nil), and a result string: "noIntersection", "intersection", "coplanar", or "badArcs"
return function(aStart, aEnd, bStart, bEnd)
	local aCross = vec3.cross(aStart, aEnd)
	local bCross = vec3.cross(bStart, bEnd)
	if #aCross == 0 or #bCross == 0 then
		return nil, "badArcs"
	end
	local aPlaneNormal = vec3.normalise(aCross)
	local bPlaneNormal = vec3.normalise(bCross)

	local normalCrossPreNormalise = vec3.cross(aPlaneNormal, bPlaneNormal)
	if #normalCrossPreNormalise == 0 then
		return nil, "coplanar" -- Not gonna check for whether the two arcs touch on the great circle that they share
	end
	local normalCross = vec3.normalise(normalCrossPreNormalise)

	local aAngle = util.angleBetweenDirections(aStart, aEnd)
	local bAngle = util.angleBetweenDirections(bStart, bEnd)

	if
		util.angleBetweenDirections(aStart, normalCross) <= aAngle and
		util.angleBetweenDirections(aEnd, normalCross) <= aAngle and
		util.angleBetweenDirections(bStart, normalCross) <= bAngle and
		util.angleBetweenDirections(bEnd, normalCross) <= bAngle
	then
		return normalCross, "intersection"
	end

	if
		util.angleBetweenDirections(aStart, -normalCross) <= aAngle and
		util.angleBetweenDirections(aEnd, -normalCross) <= aAngle and
		util.angleBetweenDirections(bStart, -normalCross) <= bAngle and
		util.angleBetweenDirections(bEnd, -normalCross) <= bAngle
	then
		return -normalCross, "intersection"
	end

	return nil, "noIntersection"
end
