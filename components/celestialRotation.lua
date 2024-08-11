local concord = require("lib.concord")
return concord.component("celestialRotation", function(c, rotationAxis, initialAngle, angularSpeed)
	c.rotationAxis = rotationAxis
	c.initialAngle = initialAngle
	c.angularSpeed = angularSpeed
end)
