local pageDisplay = require("util.pageDisplay")

---@type table<string, string[]>, table<string, string[]>
local pageLines, headerLines = {}, {}

---@type function[]
local lineCallbacks = {}

-- Convert all peripheral methods to
local sides = peripheral.getNames()
for _, side in ipairs(sides) do

	-- Initialize line tables
	headerLines[side] = {}
	pageLines[side] = {}

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
	pageLines[side] = methods

	::continue::

	-- Push pager display callback for current side
	table.insert(lineCallbacks, function ()
		pageDisplay.setup("P. Methods", headerLines[side], pageLines[side])
		pageDisplay.display()
	end)
end

pageDisplay.setup("Peripherals", {}, sides, lineCallbacks)
pageDisplay.display()
