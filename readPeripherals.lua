local pageDisplay = require("util.pageDisplay")

---@type table<string, string[]>, table<string, string[]>
local pageLines, headerLines = {}, {}

-- Convert all peripheral methods to
local sides = peripheral.getNames()
for _, side in ipairs(sides) do
	-- Initialize line tables
	pageLines[side] = {}
	headerLines[side] = {}

	-- Set peripheral headers
	local pType = peripheral.getType(side)
	table.insert(headerLines[side], "Side: " .. side)
	table.insert(headerLines[side], "Type: " .. pType)

	local methods = peripheral.getMethods(side)
	if methods == nil then
		table.insert(pageLines[side], " (No methods found!)")
		goto continue
	end

	-- Save peripheral methods in table
	for _, m in ipairs(methods) do
		table.insert(pageLines[side], " - " .. m)
	end

	::continue::
end

pageDisplay.setup(headerLines["back"], pageDisplay["back"])
