local concord = require("lib.concord")
return concord.component("atmosphere", function(c, height, colour, densityPower, scatterance, absorption, emission)
	c.height = height
	c.colour = colour
	c.densityPower = densityPower

	c.scatterance = scatterance
	c.absorption = absorption
	c.emission = emission
end)
