local quat = require("lib.mathsies").quat

local consts = require("consts")

return function(e, relativeBody)
	e:give("celestialCamera",
		relativeBody,
		consts.forwardVector * -relativeBody.celestialRadius.value * consts.cameraResetBodyRadiusDistanceRatio,
		quat(),
		consts.celestialCameraSpeedPerDistance,
		consts.celestialCameraAngularSpeed,
		consts.celestialCameraVerticalFOV
	)
end
