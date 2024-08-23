return function(x, stretchLeft, stretchRight, vertexX)
	local stretch = x < vertexX and stretchLeft or stretchRight
	return math.exp(-(x - vertexX) ^ 2 / stretch)
end
