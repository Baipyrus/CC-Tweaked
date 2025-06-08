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

-- Locally global PageDisplay state
local exit = false

local function reactor_logic()
	-- Keeping track of the scram time of reactor
	local deactivated = 0

	while not exit do
		local isActive = reactor.getStatus()

		-- Reactor scram conditions
		local damaged = reactor.getDamagePercent() > 100
		local overheated = reactor.getTemperature() > 1200
		local wasteFilled = reactor.getWasteFilledPercentage() > 95

		-- Cool-off period for reactor to recover during
		local diffTime = os.difftime(os.time(), deactivated)

		if isActive and (damaged or overheated or wasteFilled) then
			reactor.scram()
			deactivated = os.time()
		elseif not isActive and diffTime >= 60 then
			reactor.activate()
		end
	end
end

parallel.waitForAny(function()
	pd_main.display()
	exit = true
end, reactor_logic)
