return function(t)
	local ret = {}
	for k, v in pairs(t) do
		ret[k] = v
	end
	return ret
end
