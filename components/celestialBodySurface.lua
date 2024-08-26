local concord = require("lib.concord")
return concord.component("celestialBodySurface", function(c, colours, features)
	c.colours = colours
	c.features = features
end)
