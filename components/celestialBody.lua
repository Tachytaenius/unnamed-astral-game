local concord = require("lib.concord")
return concord.component("celestialBody", function(c, type)
	c.type = type -- Currently star/planet/moon. Replace with star/gas/terrestrial/etc? After all, planet/moon/whatever status is inferred from depth, as long as it isn't a star
end)
