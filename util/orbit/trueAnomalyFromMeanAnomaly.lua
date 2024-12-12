local consts = require("consts")

return function(meanAnomaly, orbit)
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
	return trueAnomaly
end
