local util = require("util")

return function(body)
	assert(body.keplerOrbit, "Can't get orbit centre for body that is not orbiting anything")
	return body.keplerOrbit.parent.celestialMotionState.position + util.getLocalOrbitCentre(body)
end
