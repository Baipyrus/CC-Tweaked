local M = {}

-- Globally accessible variables
---@type integer, integer, integer
local width, height, linesPerPage

---@type string[], string[]
local pageLines, headerLines = {}, {}

---@param bullet? boolean
---@param lines string[]
local function wrap_text_lines(lines, bullet)
	---@type string[]
	local wrapped = {}

	for _, l in ipairs(lines) do
		local current = bullet and l .. " - " or l

		-- Save peripheral methods in table
		if #current <= width then
			table.insert(wrapped, current)
			goto skip
		end

		-- Split line with wrap to account for page scrolling
		while #current > 0 do
			local c1 = current:sub(0, width)
			table.insert(wrapped, c1)

			local c2 = current:sub(width + 1)
			current = bullet and "   " .. c2 or c2
		end

		::skip::
	end

	return wrapped
end

---@param headers string[]
---@param content string[]
function M.setup(headers, content)
	-- Get terminal dimensions
	width, height = term.getSize()

	-- Subtract static content
	linesPerPage = height - 6

	-- Wrap text lines if necessary
	pageLines = wrap_text_lines(content, true)
	headerLines = wrap_text_lines(headers)
end

---@param s string
---@param prefix string
function string.startswith(s, prefix)
	return s:sub(0, #prefix) == prefix
end

function M.display()
	local currentPage = 1
	local currentSelect = 1

	while true do
		term.clear()
		term.setCursorPos(1, 1)

		-- Variables for current peripheral display
		local methodLines = linesPerPage - #headerLines - 1
		local methodPages = math.ceil(#pageLines / methodLines)

		-- Print global headers
		print("Peripherals (Page " .. currentPage .. "/" .. methodPages .. ")")
		print(string.rep("-", width))

		-- Print headers of current peripheral
		print(table.concat(headerLines, "\n"))
		print()

		-- Print current page content
		local startLine = (currentPage - 1) * methodLines + 1
		local endLine = math.min(startLine + methodLines - 1, #pageLines)
		print(table.concat(pageLines, "\n", startLine, endLine))

		-- Print global footers
		local emptyLines = methodLines - (endLine - startLine)
		print(string.rep("\n", emptyLines - 1))
		print("[ENTER] Select | [UP] Next    | [DOWN] Previous")
		print("[N]     Next   | [P] Previous | [Q] Quit       ")

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
		elseif key == keys.up or key == keys.down then
			pageLines[currentSelect] = " -" .. pageLines[currentSelect]:sub(3)

			while true do
				if key == keys.up and currentSelect < methodLines then
					currentSelect = currentSelect + 1
				elseif key == keys.down and currentSelect > 1 then
					currentSelect = currentSelect - 1
				else
					error("Could not find nearest bulletpoint!")
				end

				if pageLines[currentSelect]:startswith(" - ") then
					break
				end
			end

			pageLines[currentSelect] = " *" .. pageLines[currentSelect]:sub(3)
		end
	end
end

return M
