---Creates an independent instance of a page display
local function newPageDisplay()
	local self = {}

	-- Locally global variables
	---@type integer, integer
	local width, height

	--@type string
	local displayTitle

	---@type integer[], function[]
	local callbackIndex, lineCallbacks

	---@param bullet? boolean
	---@param lines string[]
	local function wrap_text_lines(lines, bullet)
		---@type string[]
		local wrapped = {}
		---@type integer[]
		local map = {}

		for i, l in ipairs(lines) do
			local current = bullet and " - " .. l or l

			-- Save peripheral methods in table
			if #current <= width then
				table.insert(wrapped, current)
				table.insert(map, i)
				goto skip
			end

			-- Split line with wrap to account for page scrolling
			while #current > 3 do
				local c1 = current:sub(0, width)
				table.insert(wrapped, c1)
				table.insert(map, i)

				local c2 = current:sub(width + 1)
				current = bullet and "   " .. c2 or c2
			end

			::skip::
		end

		return wrapped, map
	end

	---@param title string
	---@param headers string[]
	---@param content string[]
	---@param callbacks? function[]
	function self.setup(title, headers, content, callbacks)
		-- Get terminal dimensions
		width, height = term.getSize()

		-- Subtract static content
		self.linesPerPage = height - 4

		-- Save display title
		displayTitle = title

		-- Wrap text lines if necessary
		self.pageLines, callbackIndex = wrap_text_lines(content, true)
		self.headerLines = wrap_text_lines(headers)

		-- Save callback functions
		lineCallbacks = callbacks or {}
	end

	---@param s string
	---@param prefix string
	function string.startswith(s, prefix)
		return s:sub(0, #prefix) == prefix
	end

	---Calculates next selection index only on valid entry
	---@param goUp boolean The direction to go in
	---@param current integer The current selection index
	---@param i integer The start index of a given range
	---@param j integer The end index of a given range
	local function calculateSelection(goUp, current, i, j)
		local previous = current

		while true do
			if not goUp and current < j then
				current = current + 1
			elseif goUp and current > i then
				current = current - 1
			else
				-- Could not find nearest bulletpoint
				return previous
			end

			-- Only exit on valid entry
			if self.pageLines[current]:startswith(" - ") then
				break
			end
		end

		return current
	end

	---Gets start- and end-position of page content lines
	---@param current integer Current page index
	---@param length integer Length of page content
	---@param total integer Total content lines available
	---@return integer j The start index of a given range
	---@return integer i The end index of a given range
	local function getPageIndecies(current, length, total)
		local start = (current - 1) * length + 1
		return start, math.min(start + length - 1, total)
	end

	---Detects and handles key down events for page display
	---@param currentSelect integer
	---@param currentPage integer
	---@param contentLength integer
	---@return boolean exit Whether to quit page display
	---@return integer select The new selection index
	---@return integer page The new page index
	local function inputHandler(currentSelect, currentPage, contentLength)
		local startLine, endLine = getPageIndecies(currentPage, contentLength, #self.pageLines)
		local contentPages = math.ceil(#self.pageLines / contentLength)

		---@type _, string
		local _, key = os.pullEvent("key")

		local keyUpLogic = key == keys.up and currentSelect > startLine
		local keyDownLogic = key == keys.down and currentSelect < endLine
		local pageScrollFlag = false

		-- Select next real entry in 'self.pageLines'
		if keyUpLogic or keyDownLogic then
			self.pageLines[currentSelect] = " -" .. self.pageLines[currentSelect]:sub(3)
			currentSelect = calculateSelection(keyUpLogic, currentSelect, startLine, endLine)
			self.pageLines[currentSelect] = " *" .. self.pageLines[currentSelect]:sub(3)
		elseif key == keys.q then
			-- Quit current menu
			term.clear()
			term.setCursorPos(1, 1)

			return true, currentSelect, currentPage
		elseif key == keys.enter then
			-- Run callback method and exit
			local idx = callbackIndex[currentSelect]
			local cbak = lineCallbacks[idx]

			if cbak ~= nil then
				cbak()
			end
		elseif key == keys.n and currentPage < contentPages then
			-- Scroll next page
			currentPage = currentPage + 1
			pageScrollFlag = true
		elseif key == keys.p and currentPage > 1 then
			-- Scroll previous page
			currentPage = currentPage - 1
			pageScrollFlag = true
		end

		-- Reset current selection to nearest bulletpoint
		if pageScrollFlag then
			self.pageLines[currentSelect] = " -" .. self.pageLines[currentSelect]:sub(3)
			currentSelect = key == keys.n and endLine or startLine

			startLine, endLine = getPageIndecies(currentPage, contentLength, #self.pageLines)
			currentSelect = calculateSelection(key == keys.p, currentSelect, startLine, endLine)
			self.pageLines[currentSelect] = " *" .. self.pageLines[currentSelect]:sub(3)
		end

		return false, currentSelect, currentPage
	end

	---Renders the actual page display once
	---@param currentSelect integer
	---@param currentPage integer
	---@return boolean exit Whether to quit page display
	---@return integer select The new selection index
	---@return integer page The new page index
	function self.renderDisplay(currentSelect, currentPage)
		term.clear()
		term.setCursorPos(1, 1)

		-- Less spacing necessary if no headers provided
		local headerSpacing = #self.headerLines > 0 and 2 or 1
		-- Replacing keymap legend on small screens
		local legendLines = width >= 48 and 2 or 0

		-- Variables for current peripheral display
		local methodLines = self.linesPerPage - #self.headerLines - 1 - legendLines
		local methodPages = math.ceil(#self.pageLines / methodLines)

		-- Print global headers
		print(displayTitle .. ": (Page " .. currentPage .. "/" .. methodPages .. ")")
		print(string.rep("-", width))

		if #self.headerLines > 0 then
			-- Print headers of current peripheral
			print(table.concat(self.headerLines, "\n"))
			print()
		end

		-- Print current page content
		local startLine, endLine = getPageIndecies(currentPage, methodLines, #self.pageLines)
		print(table.concat(self.pageLines, "\n", startLine, endLine))

		-- Print global footers
		local displayLines = endLine - startLine + headerSpacing
		local emptyLines = methodLines - displayLines + 2
		local lessIfEmpty = legendLines == 0 and 1 or 0
		print(string.rep("\n", emptyLines - 1 - lessIfEmpty))

		if legendLines > 0 then
			print("[ENTER] Select | [UP] Next     | [DOWN] Previous")
			print("[N]     Next   | [P]  Previous | [Q]    Quit    ")
		end

		-- Event handling of display after rendering
		return inputHandler(currentSelect, currentPage, methodLines)
	end

	function self.display()
		local currentPage = 1
		local currentSelect = 1

		-- Set initial bulletpoint as selected
		self.pageLines[currentSelect] = " *" .. self.pageLines[currentSelect]:sub(3)

		-- Main loop: contains rendering, input logic and callbacks
		while true do
			local exit = false

			-- Update select and page indecies
			exit, currentSelect, currentPage = self.renderDisplay(currentSelect, currentPage)

			-- Exit if 'q' key down event detected
			if exit then
				break
			end
		end
	end

	return self
end

return newPageDisplay
