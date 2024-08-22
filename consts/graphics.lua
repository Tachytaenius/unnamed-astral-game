local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat

local graphics = {}

graphics.maxLightsCelestial = 64
graphics.maxShadowSpheresCelestial = 64

graphics.canvasSystemWidth = 480*2
graphics.canvasSystemHeight = 270*2

graphics.loadObjCoordMultiplier = vec3(1, 1, -1) -- Export OBJs from Blender with +Y up and +Z forward -- TODO: Why is this needed?
graphics.objectVertexFormat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal", "float", 3}
}

graphics.lineVertexFormat = {
	{"VertexPosition", "float", 3},
	{"VertexColor", "float", 3}
}

graphics.celestialNearPlaneDistance = 0.1
graphics.celestialFarPlaneDistance = 20000000
graphics.orbitLineColour = {0.25, 0.25, 0.25}
graphics.bodyReticleColour = {0.5, 0.5, 0.5}
graphics.atmosphereRayStepCount = 50

-- TODO: Same TODO as in celestial: evaluate consts in order to use consts from previous files
local tau = math.pi * 2
local rightVector = vec3(1, 0, 0)
local upVector = vec3(0, 1, 0)
local forwardVector = vec3(0, 0, 1)
graphics.cubemapOrientations = {
	quat.fromAxisAngle(upVector * tau * 0.25),
	quat.fromAxisAngle(upVector * tau * -0.25),
	quat.fromAxisAngle(rightVector * tau * 0.25),
	quat.fromAxisAngle(rightVector * tau * -0.25),
	quat(),
	quat.fromAxisAngle(upVector * tau * 0.5)
}

return graphics
