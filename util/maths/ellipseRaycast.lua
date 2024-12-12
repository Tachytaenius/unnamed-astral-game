local vec2 = require("lib.mathsies").vec2

return function(rayStart, startToEnd, ellipseCentre, ellipseXRadius, ellipseYRadius, ellipseAngle)
	if #startToEnd == 0 then
		return
	end

	local axes = vec2(ellipseXRadius, ellipseYRadius)

	local ocn = vec2.rotate(rayStart - ellipseCentre, -ellipseAngle) / axes
	local rdn = vec2.rotate(startToEnd, -ellipseAngle) / axes

	local a = vec2.dot(rdn, rdn)
	local b = vec2.dot(ocn, rdn)
	local c = vec2.dot(ocn, ocn)

	local h = b ^ 2 - a * (c - 1)
	if h < 0 then
		return
	end

	return
		(-b - math.sqrt(h)) / a,
		(-b + math.sqrt(h)) / a
end
