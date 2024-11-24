local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local list = require("lib.list")

local util = require("util")
local consts = require("consts")

return function(parameters)
	local function generateGalaxyCore()
		print("Generating galaxy...")

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
			otherStars[i] = star
		end

		-- TEMP
		local crossResult = vec3.cross(parameters.squashDirection, consts.forwardVector)
		local outVector = #crossResult == 0 and consts.rightVector or vec3.normalise(crossResult)
		local originPositionInGalaxy = outVector * parameters.gameplayOriginDistance

		-- Sort by brightness (and get directions) for constellations
		local directions = {}
		local apparentBrightnesses = {} -- For the sorting
		for _, star in ipairs(otherStars) do
			local luminousFlux = star.radiantFlux * star.luminousEfficacy
			local difference = star.position - originPositionInGalaxy
			local distance = #difference
			directions[star] = difference / distance
			apparentBrightnesses[star] = luminousFlux * distance ^ -2 -- Units of illuminance
		end
		-- print("Sorting...")
		-- This sorting shouldn't have an effect elsewhere
		table.sort(otherStars, function(a, b)
			return apparentBrightnesses[a] > apparentBrightnesses[b]
		end) -- First is brightest, last is least bright
		-- print("Sorted")
		local acceptableStars = {} -- Stars bright enough to use in constellations
		for i, star in ipairs(otherStars) do
			-- Could do it by brightness
			if i > consts.constellationAcceptableStarCount then
				break
			end
			acceptableStars[i] = star
		end
		return originPositionInGalaxy, otherStars, acceptableStars, directions, apparentBrightnesses
	end
	local originPositionInGalaxy, otherStars, acceptableStars, directions, apparentBrightnesses = generateGalaxyCore() -- Must match other calls

	local function generateConstellations() -- Return nil if rejected
		local constellationList = {}

		local starsLinkedByStar = {}
		local starToConstellation = {}
		local unclaimedStars = list()
		for _, star in ipairs(acceptableStars) do
			unclaimedStars:add(star)
			starsLinkedByStar[star] = {}
		end
		local function claimStar(star, constellation) -- Can be run multiple times on a star as long as it's always in the same constellation
			assert(not starToConstellation[star] or starToConstellation[star] == constellation, "Star is already claimed by another constellation")
			if not starToConstellation[star] then
				constellation.stars[#constellation.stars + 1] = star
			end
			starToConstellation[star] = constellation
			if unclaimedStars:has(star) then
				unclaimedStars:remove(star)
			end
		end

		local constellationCount = love.math.random(consts.constellationCountMin, consts.constellationCountMax)
		-- Pick initial constellation stars
		for i = 1, constellationCount do
			-- This could be done better.
			-- Picking a random star or, I think, getting the n brightest stars (what we do here) won't pick a random direction as much as much as picking a random direction and finding the closest (and brightest) star, due to the elliptical nature of the galaxy. But the effect should be ironed out by everything else
			local nextInitialStar = acceptableStars[i]
			for _, constellation in ipairs(constellationList) do
				local angularDistance = util.angleBetweenDirections(directions[nextInitialStar], directions[constellation.startingStar])
				if angularDistance < consts.constellationMinAngularSeparationOther then
					-- print("Starting stars too close together")
					return "remakeGalaxy" -- Blehhh, lazy
				end
			end
			local newConstellation = {
				stars = {},
				links = {},
				startingStar = nextInitialStar,
				linkTarget = love.math.random(consts.constellationConnectionMin, consts.constellationConnectionMax)
			}
			constellationList[#constellationList + 1] = newConstellation
			claimStar(nextInitialStar, newConstellation)
		end

		-- Grow constellations, going around adding one to each
		-- TODO: Are the sphereArcPointAngularDistance calls even doing their job?
		local function enoughConnections()
			for _, constellation in ipairs(constellationList) do
				if #constellation.links < constellation.linkTarget then
					return false
				end
			end
			return true
		end
		local constellationIndexStartZero = 0
		local giveUps = {} -- Also tracks constellations that have enough links
		local giveUpCount = 0
		while not enoughConnections() do
			if giveUpCount >= #constellationList then
				break
			end
			local constellation = constellationList[constellationIndexStartZero + 1]
			if not giveUps[constellation] then
				-- Add a link
				local attemptNumber = 1
				while true do -- Might take a few tries
					local starAIndex = love.math.random(#constellation.stars)
					local starA = constellation.stars[starAIndex]
					local starB
					local linkWithinSelf = #constellation.stars > 2 and love.math.random() < consts.constellationLinkToAlreadyClaimedStarChance
					if linkWithinSelf then
						local usableStars = {}
						for _, possiblyUsableStar in ipairs(constellation.stars) do
							if possiblyUsableStar ~= starA then
								-- Now check that possiblyUsableStar is not linked to starA already (if we don't do this we get links which are equivalent)
								if
									not starsLinkedByStar[starA][possiblyUsableStar]
									-- and not starsLinkedByStar[possiblyUsableStar][starA]
								then
									usableStars[#usableStars + 1] = possiblyUsableStar
								end
							end
						end
						if #usableStars == 0 then
							goto badLink
						end
						starB = usableStars[love.math.random(#usableStars)]
					else
						-- Pick an unclaimed star! One of the brightest acceptable-brightness within-distance unclaimed stars to starA should do
						local starsToSort = {}
						for _, unclaimedStar in ipairs(unclaimedStars.objects) do
							if util.angleBetweenDirections(directions[unclaimedStar], directions[constellation.startingStar]) <= consts.constellationMaxAngularSeparationFromStartStar then
								starsToSort[#starsToSort + 1] = unclaimedStar
							end
						end
						-- May not be sorted by brightness due to how Lists work
						table.sort(starsToSort, function(a, b)
							return apparentBrightnesses[a] > apparentBrightnesses[b]
						end)
						-- Pick one of the brightest 3
						local index = math.min(#starsToSort, love.math.random(1, 3))
						starB = starsToSort[index]
						if not starB then
							goto badLink
						end
					end
					-- Check for overlaps within constellation, making sure not to check if attempted link and extant link share a star
					-- Also don't get too close to links in this constellation, either
					for _, link in ipairs(constellation.links) do
						local checkForOverlap = not (
							link.a == starA or
							link.a == starB or
							link.b == starA or
							link.b == starB
						)
						if checkForOverlap and util.getSphereArcIntersections(
							directions[starA], directions[starB],
							directions[link.a], directions[link.b]
						) then
							goto badLink
						end

						if
							link.a ~= starA and link.b ~= starA and util.sphereArcPointAngularDistance(
								directions[link.a], directions[link.b],
								directions[starA]
							) <= consts.constellationMinAngularSeparationWithinSame
							or
							link.a ~= starB and link.b ~= starB and util.sphereArcPointAngularDistance(
								directions[link.a], directions[link.b],
								directions[starB]
							) <= consts.constellationMinAngularSeparationWithinSame
						then
							goto badLink
						end
					end
					-- Check for overlaps with other constellations and don't get too close to other constellation stars
					-- Also don't get too close to other constellation links, either
					for _, otherConstellation in ipairs(constellationList) do
						if otherConstellation ~= constellation then
							for _, otherConstellationStar in ipairs(otherConstellation.stars) do
								if util.angleBetweenDirections(directions[starB], directions[otherConstellationStar]) < consts.constellationMinAngularSeparationOther then
									goto badLink
								end
							end

							for _, link in ipairs(otherConstellation.links) do
								if util.getSphereArcIntersections(
									directions[starA], directions[starB],
									directions[link.a], directions[link.b]
								) then
									goto badLink
								end

								if
									util.sphereArcPointAngularDistance(
										directions[link.a], directions[link.b],
										directions[starA]
									) <= consts.constellationMinAngularSeparationOther
									or
									util.sphereArcPointAngularDistance(
										directions[link.a], directions[link.b],
										directions[starB]
									) <= consts.constellationMinAngularSeparationOther
								then
									goto badLink
								end
							end
						end
					end

					do -- Hell
						local separation = util.angleBetweenDirections(directions[starA], directions[starB])
						if not (consts.constellationLinkSeparationMin <= separation and separation <= consts.constellationLinkSeparationMax) then
							goto badLink
						end
					end

					-- Good link!
					assert(starA ~= starB, "Can't link star to itself")
					assert(starToConstellation[starA] == constellation, "Unreachable code reached") -- claimStar(starA, constellation) -- Should be in constellation already
					claimStar(starB, constellation)
					starsLinkedByStar[starA][starB] = true
					starsLinkedByStar[starB][starA] = true
					constellation.links[#constellation.links + 1] = {
						a = starA,
						b = starB
					}
					if #constellation.links >= constellation.linkTarget then
						-- Finish and don't try to add more to this constellation
						giveUps[constellation] = true
						giveUpCount = giveUpCount + 1
					end
					do break end -- Sobbing

					::badLink:: -- Was originally just a continue
					attemptNumber = attemptNumber + 1
					if attemptNumber > consts.constellationLinkFailuresBeforeGiveUpOrRetry then
						if #constellation.links >= consts.constellationConnectionMin then
							-- Give up and don't try to add more to this constellation
							giveUps[constellation] = true
							giveUpCount = giveUpCount + 1
							break
						else
							return "remakeConstellations"
						end
					end
				end
			end
			constellationIndexStartZero = (constellationIndexStartZero + 1) % #constellationList
		end

		-- Check that all links were recorded
		for _, constellation in ipairs(constellationList) do
			for _, link in ipairs(constellation.links) do
				assert(starsLinkedByStar[link.a][link.b] and starsLinkedByStar[link.b][link.a], "Star link not recorded")
			end
		end
		-- Check for identical entries in the constellations
		for _, constellation in ipairs(constellationList) do
			for i = 1, #constellation.links - 1 do
				local link1 = constellation.links[i]
				for j = i + 1, #constellation.links do
					local link2 = constellation.links[j]
					if
						link1.a == link2.a and link1.b == link2.b or
						link1.a == link2.b and link1.b == link2.a
					then
						error("Identical link detected")
					end
				end
			end
		end

		-- Not rejected! Return the list
		return constellationList
	end
	local constellationList
	local constellationRetries = 0
	repeat
		-- print("Generating constellations")
		local constellationListOrRejection = generateConstellations()
		if type(constellationListOrRejection) == "string" then
			local rejection = constellationListOrRejection
			if rejection == "remakeConstellations" then
				-- print("Remaking constellations with the galaxy")
				constellationRetries = constellationRetries + 1
				if constellationRetries > consts.constellationRetriesBeforeGalaxyRetry then
					constellationRetries = 0
					print("Remaking galaxy due to remaking constellations too many times")
					originPositionInGalaxy, otherStars, acceptableStars, directions, apparentBrightnesses = generateGalaxyCore() -- Must match other calls
				end -- -- Else this loop will run again with the same galaxy
			elseif rejection == "remakeGalaxy" then
				-- print("Remaking galaxy")
				originPositionInGalaxy, otherStars, acceptableStars, directions, apparentBrightnesses = generateGalaxyCore() -- Must match other calls
			else
				error("Unknown return from generateConstellations \"" .. rejection .. "\"")
			end
		elseif constellationListOrRejection == nil then
			error("Must return either \"remakeConstellations\" or \"remakeGalaxy\" from generateConstellations to be explicit")
		else
			constellationList = constellationListOrRejection -- This is hopefully a table lol
		end
	until constellationList
	print("Constellations accepted")

	return {
		otherStars = otherStars,
		originPositionInGalaxy = originPositionInGalaxy,
		constellations = constellationList,

		forwards = parameters.squashDirection,
		squashAmount = parameters.squashAmount,
		radius = parameters.radius,
		galaxyHaloProportion = parameters.haloProportion
	}
end
