local concord = require("lib.concord")
return concord.component("textureCubemaps", function(c, seed, baseColour, normal, height)
	c.seed = seed
	c.baseColour = baseColour
	c.normal = normal
	c.height = height
end)
