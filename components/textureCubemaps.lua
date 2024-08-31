local concord = require("lib.concord")
return concord.component("textureCubemaps", function(c, seed, baseColour, normal)
	c.seed = seed
	c.baseColour = baseColour
	c.normal = normal
end)
