local concord = require("lib.concord")
return concord.component("keplerOrbit", function(c, parent,
	semiMajorAxis,
	eccentricity,
	argumentOfPeriapsis,
	initialMeanAnomaly,
	longitudeOfAscendingNode,
	inclination
)
	c.parent = parent

	c.semiMajorAxis = semiMajorAxis
	c.eccentricity = eccentricity
	c.argumentOfPeriapsis = argumentOfPeriapsis
	c.initialMeanAnomaly = initialMeanAnomaly
	c.longitudeOfAscendingNode = longitudeOfAscendingNode
	c.inclination = inclination
end)
