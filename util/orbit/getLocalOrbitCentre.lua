local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3

local util = require("util")

return function(body)
	-- Relative to body's parent
	-- Figured this out from one relation without finding any proper resources on the exact problem (TODO: Redo?)
	local orbit = body.keplerOrbit
	local periapsisDirection = vec2.fromAngle(orbit.argumentOfPeriapsis)
	local periapsisDistance = orbit.semiMajorAxis * (1 - orbit.eccentricity)
	local apoapsisDistance = orbit.semiMajorAxis * (1 + orbit.eccentricity)
	local centreOrbitalPlane = periapsisDirection * (periapsisDistance - apoapsisDistance) / 2
	return vec3.rotate(
		vec3(centreOrbitalPlane.x, centreOrbitalPlane.y, 0),
		util.getOrbitalPlaneRotation(body)
	)
end
