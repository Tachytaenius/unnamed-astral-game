local concord = require("lib.concord")
return concord.component("celestialBody", function(c, type)
	c.type = type
end)
