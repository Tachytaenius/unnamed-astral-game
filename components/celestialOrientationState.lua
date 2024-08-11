local concord = require("lib.concord")
return concord.component("celestialOrientationState", function(c, value)
	c.value = value
end)
