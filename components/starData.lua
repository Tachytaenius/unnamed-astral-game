local concord = require("lib.concord")
return concord.component("starData", function(c, luminosity, colour)
	c.luminosity = luminosity
	c.colour = colour
	-- TODO: Non-hardcoded sunspot data
end)
