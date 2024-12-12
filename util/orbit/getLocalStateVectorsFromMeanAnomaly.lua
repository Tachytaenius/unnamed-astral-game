local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3

local consts = require("consts")
local util = require("util")

return function(meanAnomaly, body)
	local orbit = body.keplerOrbit
	local standardGravitationalParameter = consts.gravitationalConstant * orbit.parent.celestialMass.value

	local e = meanAnomaly
	local f = e - orbit.eccentricity * math.sin(e) - meanAnomaly
	local i = 0
	while math.abs(f) > consts.orbitNewtonRaphsonEpsilon and i < consts.maxOrbitNewtonRaphsonIterations do
		e = e - f / (1 - orbit.eccentricity * math.cos(e))
		f = e - orbit.eccentricity * math.sin(e) - meanAnomaly
		i = i + 1
	end
	local eccentricAnomaly = e

	local trueAnomaly = 2 * math.atan2(
		math.sqrt(1 + orbit.eccentricity) * math.sin(eccentricAnomaly / 2),
		math.sqrt(1 - orbit.eccentricity) * math.cos(eccentricAnomaly / 2)
	)
	local distance = orbit.semiMajorAxis * (1 - orbit.eccentricity * math.cos(eccentricAnomaly))

	local position2D = vec2.fromAngle(trueAnomaly + orbit.argumentOfPeriapsis) * distance
	local velocity2D = math.sqrt(standardGravitationalParameter * orbit.semiMajorAxis) / distance * vec2(
		-math.sin(eccentricAnomaly + orbit.argumentOfPeriapsis),
		math.sqrt(1 - orbit.eccentricity ^ 2) * math.cos(eccentricAnomaly + orbit.argumentOfPeriapsis)
	)
	local rotation = util.getOrbitalPlaneRotation(body)

	-- TODO: Test velocity
	return
		vec3.rotate(vec3(position2D.x, position2D.y, 0), rotation),
		vec3.rotate(vec3(velocity2D.x, velocity2D.y, 0), rotation)
end
