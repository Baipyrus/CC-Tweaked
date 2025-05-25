term.clear()

-- Get terminal dimensions
local width, height = term.getSize()
-- Subtract static content
local linesPerPage = height - 5

local sides = peripheral.getNames()
---@type table<string, string[]>, table<string, string[]>
local pageLines, headerLines = {}, {}

-- Convert all peripheral methods to
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

	for _, m in ipairs(methods) do
		local methodLine = " - " .. m

		-- Save peripheral methods in table
		if #methodLine <= width then
			table.insert(pageLines[side], methodLine)
			goto skip
		end

		-- Split line with wrap to account for page scrolling
		while #methodLine > 0 do
			local lineSplit = methodLine:sub(0, width)
			table.insert(pageLines[side], lineSplit)

			methodLine = methodLine:sub(width + 1)
		end

		::skip::
	end

	::continue::
end

-- Main loop/logic
local currentPage = 1
local currentSide = "back"

while true do
	term.clear()
	term.setCursorPos(1, 1)

	-- Variables for current peripheral display
	local currentLines = pageLines[currentSide]
	local methodLines = linesPerPage - #headerLines[currentSide]
	local methodPages = math.ceil(#currentLines / methodLines)

	-- Print global headers
	print("Peripherals (Page " .. currentPage .. "/" .. methodPages .. ")")
	print(string.rep("-", width))

	-- Print headers of current peripheral
	print(table.concat(headerLines[currentSide], "\n"))

	-- Print current page content
	-- TODO: Page scrolling can break due to line wrap
	local startLine = (currentPage - 1) * methodLines + 1
	local endLine = math.min(startLine + methodLines - 1, #currentLines)
	print(table.concat(currentLines, "\n", startLine, endLine))

	-- Print global footers
	print("\n[N] Next | [P] Previous | [Q] Quit")

	-- Event handler: scroll pages or quit
	local _, key = os.pullEvent("key")
	if key == keys.q then
		term.clear()
		term.setCursorPos(1, 1)
		break
	elseif key == keys.n and currentPage < methodPages then
		currentPage = currentPage + 1
	elseif key == keys.p and currentPage > 1 then
		currentPage = currentPage - 1
	end
end
