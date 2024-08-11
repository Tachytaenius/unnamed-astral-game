local consts = {}

-- Not designed to handle random stuff in the consts folder
for _, name in ipairs(love.filesystem.getDirectoryItems("consts")) do
	if name ~= "init.lua" then
		local table = require("consts." .. name:gsub("%.lua$", ""))
		for k, v in pairs(table) do
			if consts[k] then
				error("Duplicate constant \"" .. k .. "\"")
			end
			consts[k] = v
		end
	end
end

return consts
