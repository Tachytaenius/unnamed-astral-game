local concord = require("lib.concord")
return concord.component("starData", function(c, radiantFlux, luminousEfficacy, colour)
	c.radiantFlux = radiantFlux
	c.luminousEfficacy = luminousEfficacy
	-- luminousFlux = radiantFlux * luminousEfficacy
	c.colour = colour
end)
