-- Hacky solution (TEMP)

-- local mathsies = require("lib.mathsies")
-- local vec2 = mathsies.vec2

return function(angularRadius)
	-- return 1 - vec2.rotate(vec2(1, 0), angularRadius).x
	return 1 - math.cos(angularRadius)
end
