local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3
local quat = mathsies.quat

local consts = require("consts")
local util = require("util")

return function(ellipseCentre, ellipseOrientation, ellipseXRadius, ellipseYRadius, planeNormal, planeDistance)
	local inverseEllipseOrientation = quat.inverse(ellipseOrientation)

	local ellipsePlaneNormal = vec3.rotate(consts.forwardVector, ellipseOrientation)
	local ellipsePlaneDistance = ellipsePlaneNormal * vec3.dot(ellipsePlaneNormal, ellipseCentre)

	local lineStart, lineDirection = util.planePlaneIntersection(planeNormal, planeDistance, ellipsePlaneNormal, ellipsePlaneDistance) -- Line is the intersection of the ellipse's plane with the plane we're testing the ellipse with

	local lineStart2D = vec2(vec3.components(
		vec3.rotate(lineStart - ellipseCentre, inverseEllipseOrientation)
	))
	local lineDirection2D = vec2(vec3.components(
		vec3.rotate(lineDirection, inverseEllipseOrientation)
	))
	local tA, tB = util.ellipseRaycastUnrotated(lineStart2D, lineDirection2D, vec2(), ellipseXRadius, ellipseYRadius)

	if not tA and tB then
		return
	end

	local a2D = lineStart2D + lineDirection2D * tA
	local b2D = lineStart2D + lineDirection2D * tB
	return
		vec3.rotate(vec3(a2D.x, a2D.y, 0), ellipseOrientation) + ellipseCentre,
		vec3.rotate(vec3(b2D.x, b2D.y, 0), ellipseOrientation) + ellipseCentre,
		a2D, b2D -- Bonus, return within the ellipse's reference frame :3 (origin at ellipse centre)
end
