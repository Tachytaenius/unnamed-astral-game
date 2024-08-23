local concord = require("lib.concord")
return concord.component("albedoCubemap", function(c, seed, value)
	c.seed = seed
	c.value = value
end)
