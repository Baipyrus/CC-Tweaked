local PageDisplay = require("util.pageDisplay")

---@class FusionReactorLogicAdapter
---@field isFormed fun(): boolean
---@field isIgnited fun(): boolean

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
local porters = { peripheral.find("quantumEntangloporter") }
if #porters ~= #reactors then
	error("# of entangloporters needs to equal # of reactors!")
end

---@type ccTweaked.peripherals.Inventory[]
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local controllers = { peripheral.find("minecraft:barrel") }
if #controllers ~= #reactors then
	error("# of barrels needs to equal # of reactors! One barrel per controller.")
end

---@type ccTweaked.peripherals.Inventory
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local hohlraum = peripheral.find("minecraft:chest")

if hohlraum == nil then
	error("You must place a chest to put D-T Hohlraum into!")
end

---@type string[]
local headerLines = {
	"Status: Off",
	"Ready: No",
	"Mode: Manual",
}

---@type string[]
local pageLines = {
	"scram",
	"activate",
	"Connect Matrix",
}

-- Flag to denote manual scram. Does not reactivate
local manuallyDeactivated = false

---@param display table
---@param status boolean
---@param ready boolean
local function update_headers(display, status, ready)
	local s_txt = status and "On" or "Off"
	display.headerLines[1] = "Status: " .. s_txt

	local r_txt = ready and "Yes" or "No"
	display.headerLines[2] = "Ready: " .. r_txt
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
	function()
		local pd_matrix = PageDisplay()

		local modem = peripheral.find("modem")
		if modem == nil then
			return
		end

		rednet.open(peripheral.getName(modem))

		pd_matrix.setup("Protocol Broadcasts", {}, { "None" })

		local exit_listener = false

		---@type table<string, 1>
		local protocols = {}

		local function matrix_listener()
			while not exit_listener do
				local _, _, p = rednet.receive()
				if p == nil then
					goto continue
				end

				protocols[p] = 1

				---@type string[]
				local p_keys = {}
				for k, _ in pairs(protocols) do
					table.insert(p_keys, k)
				end

				pd_matrix.setup("Protocol Broadcast", {}, p_keys)

				::continue::
			end
		end

		parallel.waitForAny(function()
			pd_matrix.display()
			exit_listener = true
		end, matrix_listener)
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
		local isReady = all_ready()
		local isActive = (function()
			for _, r in ipairs(reactors) do
				if r.isIgnited() then
					return true
				end
			end

			return false
		end)()
		update_headers(pd_main, isActive, isReady)

		-- Reactor scram conditions
		-- local damaged = reactor.getDamagePercent() > 0.8

		-- Cool-off period for reactor to recover during
		local diffTime = os.clock() - deactivated

		-- if isActive and false then
		-- 	scram()
		-- 	deactivated = os.clock()
		-- elseif not isActive and diffTime >= 60 and not manuallyDeactivated and isReady then
		-- 	activate()
		-- end
	end
end

parallel.waitForAny(function()
	pd_main.display()
	exit = true
end, reactor_logic)
