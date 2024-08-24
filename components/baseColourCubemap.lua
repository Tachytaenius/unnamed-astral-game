local concord = require("lib.concord")
return concord.component("baseColourCubemap", function(c, seed, value)
	c.seed = seed
	c.value = value
end)
