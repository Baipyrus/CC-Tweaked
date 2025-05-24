term.clear()
-- Base height of built-in computer display
-- TODO: Detect display/monitor width?
local linesPerPage = 14

local sides = peripheral.getNames()
local allLines = {}

-- Convert all peripheral methods to
for _, side in ipairs(sides) do
	-- Set peripheral headers
	local pType = peripheral.getType(side)
	table.insert(allLines, "Side: " .. side)
	table.insert(allLines, "Type: " .. pType)
	table.insert(allLines, "")

	local methods = peripheral.getMethods(side)
	if methods == nil then
		table.insert(allLines, " (No methods found!)")
		goto continue
	end

	-- Save peripheral methods in table
	for _, m in ipairs(methods) do
		table.insert(allLines, " - " .. m)
	end

	::continue::
end

-- Main loop/logic
local currentPage = 1
local totalPages = math.ceil(#allLines / linesPerPage)

while true do
	term.clear()
	term.setCursorPos(1, 1)

	-- Print global headers
	print("Peripherals (Page " .. currentPage .. "/" .. totalPages .. ")")
	print("--------------------------------")

	-- Print current page content
	-- TODO: Page scrolling can break due to line wrap
	local startLine = (currentPage - 1) * linesPerPage + 1
	local endLine = math.min(startLine + linesPerPage - 1, #allLines)
	print(table.concat(allLines, "\n", startLine, endLine))

	-- Print global footers
	print("\n[N] Next | [P] Previous | [Q] Quit")

	-- Event handler: scroll pages or quit
	local _, key = os.pullEvent("key")
	if key == keys.q then
		term.clear()
		term.setCursorPos(1, 1)
		break
	elseif key == keys.n and currentPage < totalPages then
		currentPage = currentPage + 1
	elseif key == keys.p and currentPage > 1 then
		currentPage = currentPage - 1
	end
end
