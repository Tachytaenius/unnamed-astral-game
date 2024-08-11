local consts = require("consts")

return function(segments)
	local verticesToUse = {}
	local vertices = {} -- Actual triangle data
	for i = 0, segments - 1 do
		local angle = consts.tau * i / segments
		verticesToUse[#verticesToUse + 1] = {
			math.cos(angle), math.sin(angle), 0,
			1, 1, 1
		}
	end
	for i = 0, segments - 1 do
		local a = verticesToUse[i + 1]
		local b = verticesToUse[(i + 1) % #verticesToUse + 1]
		vertices[#vertices + 1] = a
		vertices[#vertices + 1] = a
		vertices[#vertices + 1] = b
	end
	return love.graphics.newMesh(consts.lineVertexFormat, vertices, "triangles")
end
