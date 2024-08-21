local vec3 = require("lib.mathsies").vec3

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

return graphics
