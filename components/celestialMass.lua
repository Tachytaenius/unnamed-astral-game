local concord = require("lib.concord")
return concord.component("celestialMass", function(c, value)
	c.value = value
end)
