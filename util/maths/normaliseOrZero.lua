local vec3 = require("lib.mathsies").vec3

return function(v)
	local magnitude = #v
	if magnitude == 0 then
		return vec3()
	end
	return v / magnitude
end
