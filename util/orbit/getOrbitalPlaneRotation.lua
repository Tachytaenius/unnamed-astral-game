local quat = require("lib.mathsies").quat

local util = require("util")

return function(body)
	-- Does not include argument of periapsis; cannot be used as-is for drawing orbit lines
	if not body.keplerOrbit then
		error("A body which is not a satellite does not have an orbital plane rotation")
	end
	return quat.fromAxisAngle(util.getAscendingNodeDirection(body) * body.keplerOrbit.inclination)
	-- return quat.fromAxisAngle(consts.forwardVector * body.longitudeOfAscendingNode) * quat.fromAxisAngle(consts.rightVector * body.inclination)
end
