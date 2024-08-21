local concord = require("lib.concord")
return concord.component("atmosphere", function(c, height, colour, density, luminousFlux, densityPower)
	c.height = height
	c.colour = colour
	c.density = density
	c.luminousFlux = luminousFlux
	c.densityPower = densityPower
end)
