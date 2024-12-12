local consts = require("consts")

return function(trueAnomaly, orbit)
	return (
		math.atan2(
			-math.sqrt(1 - orbit.eccentricity ^ 2) * math.sin(trueAnomaly),
			-orbit.eccentricity - math.cos(trueAnomaly)
		)
		+ consts.tau / 2
		- orbit.eccentricity * (
			math.sqrt(1 - orbit.eccentricity ^ 2) * math.sin(trueAnomaly)
		) / (1 + orbit.eccentricity * math.cos(trueAnomaly))
	) % consts.tau -- I'm not 100% sure this modulo is needed
end

-- return function(trueAnomaly, orbit)
-- 	local cosTrueAnomaly = math.cos(trueAnomaly)
-- 	local acosInput =
-- 		(orbit.eccentricity + cosTrueAnomaly) /
-- 		(1 + orbit.eccentricity * cosTrueAnomaly)
-- 	local acosInputClamped = math.max(-1, math.min(1, acosInput)) -- Just in case we get a NaN otherwise
-- 	local eccentricAnomaly = math.acos(acosInputClamped)
-- 	eccentricAnomaly = math.abs(eccentricAnomaly) * util.sign(trueAnomaly) -- "Use the value that has the same sign as the true anomaly" (we get wrong answers if the sign isn't correct)
-- 	local meanAnomaly = (eccentricAnomaly - orbit.eccentricity * math.sin(eccentricAnomaly)) % consts.tau
-- 	return meanAnomaly
-- end
