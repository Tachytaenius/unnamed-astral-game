local util = require("util")

return function(trueAnomaly, orbit)
	local meanAnomaly = util.meanAnomalyFromTrueAnomaly(trueAnomaly, orbit)
	return util.getTimeFromMeanAnomaly(meanAnomaly, orbit)
end
