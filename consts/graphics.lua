local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat

local graphics = {}

graphics.maxLightsCelestial = 16
graphics.maxShadowSpheresCelestial = 16
graphics.maxShadowRingsCelestial = 16

graphics.canvasSystemWidth = 480*2
graphics.canvasSystemHeight = 270*2

graphics.loadObjCoordMultiplier = vec3(1, 1, -1) -- Export OBJs from Blender with +Y up and +Z forward -- TODO: Why is this needed?
graphics.objectVertexFormat = {
	{name = "VertexPosition", location = 0, format = "floatvec3"},
	{name = "VertexTexCoord", location = 1, format = "floatvec2"},
	{name = "VertexNormal", location = 2, format = "floatvec3"}
}

graphics.lineVertexFormat = {
	{name = "VertexPosition", location = 0, format = "floatvec3"},
	{name = "VertexColor", location = 1, format = "floatvec3"}
}

graphics.blurredPointVertexFormat = {
	{name = "VertexPosition", location = 0, format = "floatvec2"},
	{name = "VertexFade", location = 1, format = "float"}
}
graphics.blurredPointInstanceVertexFormat = {
	{name = "InstanceDirection", location = 0, format = "floatvec3"},
	{name = "InstanceColour", location = 1, format = "floatvec3"}
}

graphics.celestialNearPlaneDistance = 2e5 -- One order of magnitude below megametres
graphics.celestialFarPlaneDistance = 2e13
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
graphics.cubemapOrientationsYFlip = {}
for i, v in ipairs(graphics.cubemapOrientations) do
	graphics.cubemapOrientationsYFlip[i] = v
end
graphics.cubemapOrientationsYFlip[3], graphics.cubemapOrientationsYFlip[4] = graphics.cubemapOrientationsYFlip[4], graphics.cubemapOrientationsYFlip[3]

graphics.bodyTextureCubemapSideLength = 1024
assert(
	math.log(graphics.bodyTextureCubemapSideLength, 2) % 1 == 0,
	"bodyTextureCubemapSideLength should be a power of two to not break min/max heightmap value calculation" -- This could probably be solved somehow but enforcing power of two is much simpler
)
graphics.bodyCubemapTextureSlotCount = 6
graphics.bodyTextureCubemapSlotClaimFudgeFactor = 1.5
graphics.bodySolidOrPointFudgeFactor = 0.85
graphics.missingTextureSubdivisions = 9
graphics.missingTextureColourA = {1, 0, 1}
graphics.missingTextureColourB = {0, 0, 0}

graphics.skyboxCubemapSideLength = 2048
graphics.coronaReductionTextureSideLength = 512

graphics.pointLightBlurAngularRadius = 0.005
graphics.blurredPointDiskMeshVertices = 8
graphics.blurredPointVertexFadePower = 5
graphics.pointLuminanceToRGBNonHDR = 1e4
graphics.distantStarBodyBrightness = 100

graphics.bodyHeightmapFormat = "r32f"

graphics.galaxyRaySteps = 20

return graphics
