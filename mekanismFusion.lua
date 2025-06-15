local PageDisplay = require("util.pageDisplay")

---@class FusionReactorLogicAdapter
---@field isFormed fun(): boolean
---@field isIgnited fun(): boolean

---@class FusionReactorController
---@field pullItems fun(fromName: string, fromSlot: number)
---@field list fun(): ccTweaked.peripherals.inventory.itemList

---@class LaserAmplifier
---@field setRedstoneMode fun(mode: "HIGH" | "LOW")
---@field getEnergyFilledPercentage fun(): integer

---@class QuantumEntangloporter
---@field setEjecting fun(type: "CHEMICAL", ejecting: boolean)

---@type FusionReactorLogicAdapter[]
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local reactors = { peripheral.find("fusionReactorLogicAdapter") }
if #reactors == 0 then
	error("Could not find Fusion Reactor(-s)!")
end

---@param rs FusionReactorLogicAdapter[]
local function all_formed(rs)
	for _, r in ipairs(rs) do
		if not r.isFormed() or r["isIgnited"] == nil then
			return false
		end
	end

	return true
end

print("Waiting for reactors to form ...")
while not all_formed(reactors) do
	os.sleep(0.1)

	-- Reread reactor API methods
	---@type FusionReactorLogicAdapter[]
	---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
	reactors = { peripheral.find("fusionReactorLogicAdapter") }
	assert(#reactors > 0, "Reactor(-s) disconnected!")
end

---@type LaserAmplifier[]
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local lasers = { peripheral.find("laserAmplifier") }
if #lasers ~= #reactors then
	error("# of lasers needs to equal # of reactors!")
end

---@type QuantumEntangloporter[]
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local porters = { peripheral.find("quantumEntangloporters") }
if #porters ~= #reactors then
	error("# of entangloporters needs to equal # of reactors!")
end

---@type FusionReactorController[]
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local controllers = { peripheral.find("mekanismgenerators:fusion_reactor_controller") }
if #controllers ~= #reactors then
	error("# of controllers needs to equal # of reactors!")
end

local hohlraum = peripheral.find("inventory", function(_, wrapped)
	for _, item in pairs(wrapped.list()) do
		-- Works for D-T Fuel filled Holhraum aswell
		if item.name == "mekanismgenerators:hohlraum" then
			return true
		end
	end

	return false
end)

if hohlraum == nil then
	error("No inventory containing D-T filled Hohlraum was found!")
end

---@type string[]
local headerLines = {
	"Status: Off",
	"Ready: No",
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

local function scram()
	for _, p in ipairs(porters) do
		p.setEjecting("CHEMICAL", false)
	end
end

local function all_ready()
	for _, l in ipairs(lasers) do
		if l.getEnergyFilledPercentage() ~= 1 then
			return false
		end
	end

	return #(hohlraum.list()) >= #reactors
end

local function activate()
	if not all_ready() then
		return
	end

	-- Insert Hohlraum
	for _, c in ipairs(controllers) do
		-- Hohlraum already inside controller
		if #(c.list()) > 0 then
			goto continue
		end

		-- Find next slot with hohlraum in it
		local slot = -1
		for s, item in pairs(hohlraum.list()) do
			if item.name == "mekanismgenerators:hohlraum" then
				slot = s
				break
			end
		end

		c.pullItems(peripheral.getName(hohlraum), slot)
		::continue::
	end

	-- Inject fuel
	for _, p in ipairs(porters) do
		p.setEjecting("CHEMICAL", true)
	end

	-- Shoot lasers
	for _, l in ipairs(lasers) do
		l.setRedstoneMode("LOW")
	end

	-- Wait to disable lasers
	os.sleep(1)
	for _, l in ipairs(lasers) do
		l.setRedstoneMode("HIGH")
	end
end

---@type function[]
local lineCallbacks = {
	function()
		manuallyDeactivated = true
		scram()
	end,
	function()
		manuallyDeactivated = false
		activate()
	end,
}

-- Initialize PageDisplay object for manual control
local pd_main = PageDisplay()
pd_main.setup("M. Fusion Reactor", headerLines, pageLines, lineCallbacks)

-- Locally global PageDisplay state
local exit = false

local function reactor_logic()
	-- Keeping track of the scram time of reactor
	local deactivated = 0

	while not exit do
		-- local isActive = reactor.getStatus()
		-- update_headers(pd_main, isActive)
		--
		-- -- Reactor scram conditions
		-- local damaged = reactor.getDamagePercent() > 0.8
		-- local overheated = reactor.getTemperature() > 1000
		-- local wasteFilled = reactor.getWasteFilledPercentage() > 0.95
		-- local heatedFilled = reactor.getHeatedCoolantFilledPercentage() > 0
		--
		-- -- Cool-off period for reactor to recover during
		-- local diffTime = os.clock() - deactivated
		--
		-- if isActive and (damaged or overheated or wasteFilled or heatedFilled) then
		-- 	pcall(reactor.scram)
		-- 	deactivated = os.clock()
		-- elseif not isActive and diffTime >= 60 and not manuallyDeactivated then
		-- 	pcall(reactor.activate)
		-- end
	end
end

parallel.waitForAny(function()
	pd_main.display()
	exit = true
end, reactor_logic)
