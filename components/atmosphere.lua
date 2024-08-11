local concord = require("lib.concord")
return concord.component("atmosphere", function(c, height, colour, density, emissiveness, densityPower)
	c.height = height
	c.colour = colour
	c.density = density
	c.emissiveness = emissiveness
	c.densityPower = densityPower
end)
