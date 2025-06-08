local PageDisplay = require("util.pageDisplay")

---@class FissionReactor
---@field getStatus fun(): boolean
---@field scram function
---@field getDamagePercent function
---@field isFormed fun(): boolean
---@field getWasteFilledPercentage fun(): integer
---@field activate function
---@field getTemperature fun(): integer

---@type FissionReactor?
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local reactor = peripheral.find("fissionReactorLogicAdapter")
if reactor == nil then
	error("Could not find Fission Reactor!")
end

---@type string[]
local headerLines = {
	"Status: " .. (reactor.getStatus() and "On" or "Off"),
}

---@type string[]
local pageLines = {
	"scram",
	"activate",
}

---@type function[]
local lineCallbacks = {
	function()
		reactor.scram()
	end,
	function()
		reactor.activate()
	end,
}

-- Initialize PageDisplay object for manual control
local pd_main = PageDisplay()
pd_main.setup("M. Fission Reactor", headerLines, pageLines, lineCallbacks)

-- Exit condition for reactor logic
local exit = false

-- Display UI in a coroutine to parallelize logic
local display_coroutine = coroutine.create(function()
	pd_main.display(true)
	exit = true
end)
-- Main event loop
while not exit do
	local display_dead = coroutine.status(display_coroutine) == "dead"

	-- Resume display, if running
	if not display_dead then
		coroutine.resume(display_coroutine)
	end
end
