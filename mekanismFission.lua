local PageDisplay = require("util.pageDisplay")

---@class FissionReactor
---@field getStatus fun(): boolean
---@field scram function
---@field getDamagePercent function
---@field getHeatedCoolantFilledPercentage fun(): integer
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

print("Waiting for reactor to form ...")
while not reactor.isFormed() or reactor["getStatus"] == nil do
	os.sleep(0.1)

	-- Reread reactor API methods
	---@type FissionReactor?
	---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
	reactor = peripheral.find("fissionReactorLogicAdapter")
	assert(reactor ~= nil, "Reactor disconnected!")
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

-- Flag to denote manual scram. Does not reactivate
local manuallyDeactivated = false

---@param display table
---@param status boolean
local function update_status(display, status)
	local s_txt = status and "On" or "Off"
	display.headerLines[1] = "Status: " .. s_txt
end

---@type function[]
local lineCallbacks = {
	function()
		manuallyDeactivated = true
		pcall(reactor.scram)
	end,
	function()
		manuallyDeactivated = false
		pcall(reactor.activate)
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
		update_status(pd_main, isActive)

		-- Reactor scram conditions
		local damaged = reactor.getDamagePercent() > 0.8
		local overheated = reactor.getTemperature() > 1000
		local wasteFilled = reactor.getWasteFilledPercentage() > 0.95
		local heatedFilled = reactor.getHeatedCoolantFilledPercentage() > 0

		-- Cool-off period for reactor to recover during
		local diffTime = os.clock() - deactivated

		if isActive and (damaged or overheated or wasteFilled or heatedFilled) then
			pcall(reactor.scram)
			deactivated = os.clock()
		elseif isActive and manuallyDeactivated then
			manuallyDeactivated = false
		elseif not isActive and diffTime >= 60 and not manuallyDeactivated then
			pcall(reactor.activate)
		end
	end
end

parallel.waitForAny(function()
	pd_main.display()
	exit = true
end, reactor_logic)
