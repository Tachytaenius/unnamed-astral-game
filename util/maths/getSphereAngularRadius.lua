return function(radius, distance)
	return math.acos(math.sqrt(distance ^ 2 - radius ^ 2) / distance)
end
