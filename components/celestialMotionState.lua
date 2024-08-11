local concord = require("lib.concord")
return concord.component("celestialMotionState", function(c, position, velocity)
	c.position = position
	c.velocity = velocity
end)
