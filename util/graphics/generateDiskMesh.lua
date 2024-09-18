local consts = require("consts")

return function(segments)
	local vertices = {
		{
			0, 0, 0,
			0
		}
	}
	for i = 0, segments do
		local angle = consts.tau * i / segments
		vertices[#vertices + 1] = {
			math.cos(angle), math.sin(angle), 0,
			1
		}
	end
	return love.graphics.newMesh(consts.blurredPointVertexFormat, vertices, "fan")
end
