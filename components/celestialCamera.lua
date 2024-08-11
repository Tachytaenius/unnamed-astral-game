local concord = require("lib.concord")
return concord.component("celestialCamera", function(c, relativeTo, relativePosition, orientation, speedPerDistance, angularSpeed, verticalFOV)
	c.relativeTo = relativeTo
	c.relativePosition = relativePosition
	-- absolutePosition is also a field, but is initialised later
	c.orientation = orientation
	c.speedPerDistance = speedPerDistance
	c.angularSpeed = angularSpeed
	c.verticalFOV = verticalFOV
end)
