local concord = require("lib.concord")
return concord.component("celestialRadius", function(c, value)
	c.value = value
end)
