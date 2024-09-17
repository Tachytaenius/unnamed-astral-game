local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3

local util = require("util")
local consts = require("consts")

return function(parameters)
	local function generatePosition(halo)
		local position = util.randomOnSphereSurface(love.math.random() ^ parameters.distancePower * parameters.radius)
		if not halo then
			return position
		end
		return util.multiplyVectorInDirection(position, parameters.squashDirection, parameters.squashAmount)
	end

	local otherStars = {}
	for i = 1, parameters.otherStarCount do
		local star = {}
		star.position = generatePosition(love.math.random() < parameters.haloProportion)
		star.mass = util.randomRange(1.5e29, 1.5e31) -- Based on largest and smallest known stars
		star.radiantFlux = util.starMassToRadiantFlux(star.mass)
		star.luminousEfficacy = util.randomRange(90, 100)
		local colourVector = vec3(
			util.randomRange(0.5, 1),
			util.randomRange(0.5, 1),
			util.randomRange(0.5, 1)
		)
		-- Scale colourVector such that its largest component is 1 and the others go with it
		colourVector = colourVector / math.max(
			colourVector.x,
			math.max(
				colourVector.y,
				colourVector.z
			)
		)
		star.colour = {vec3.components(colourVector)}
		-- Luminous flux is radiantFlux * luminousEfficacy
		otherStars[i] = star
	end

	-- TEMP
	local crossResult = vec3.cross(parameters.squashDirection, consts.forwardVector)
	local outVector = #crossResult == 0 and consts.rightVector or vec3.normalise(crossResult)
	local originPositionInGalaxy = outVector * parameters.gameplayOriginDistance

	return otherStars, originPositionInGalaxy
end
