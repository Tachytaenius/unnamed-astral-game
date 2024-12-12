local consts = require("consts")

return function(meanAnomaly, orbit)
	local standardGravitationalParameter = consts.gravitationalConstant * orbit.parent.celestialMass.value
	local meanMotion = math.sqrt(standardGravitationalParameter / orbit.semiMajorAxis ^ 3)
	local timeSincePeriapsis = (meanAnomaly - orbit.initialMeanAnomaly) / meanMotion
	if timeSincePeriapsis < 0 then
		local orbitalPeriod = consts.tau / meanMotion
		timeSincePeriapsis = timeSincePeriapsis + orbitalPeriod
	end
	return timeSincePeriapsis
end
