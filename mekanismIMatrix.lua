local PageDisplay = require("util.pageDisplay")

---@class InductionMatrix
---@field getEnergyFilledPercentage fun(): number

-- Startup time, in seconds, to keep track of broadcast uptime
local startup = math.floor(os.clock())

---@type InductionMatrix
---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
local matrix = peripheral.find("inductionPort")
if matrix == nil then
	error("No induction matrix port found!")
end

local modem = peripheral.find("modem")
if modem == nil then
	error("No modem to connect with was found!")
end

rednet.open(peripheral.getName(modem))

print("Input protocol name for energy level broadcast:")
local protocol = read()

rednet.host(protocol, "inductionMatrix")

---@type string[]
local pageLines = {
	"Broadcasting: " .. protocol,
	"Uptime: 0 sec.",
}

---@param display table
---@param time integer
local function update_time(display, time)
	local u_txt = time .. " sec."
	display.pageLines[2] = " - Uptime: " .. u_txt
end

local pd_main = PageDisplay()
pd_main.setup("M. Induction Matrix", {}, pageLines)

-- Locally global PageDisplay state
local exit = false

local function matrix_logic()
	while not exit do
		local uptime = math.floor(os.clock()) - startup
		update_time(pd_main, uptime)

		rednet.broadcast(matrix.getEnergyFilledPercentage(), protocol)
	end
end

parallel.waitForAny(function()
	pd_main.display()
	exit = true
end, matrix_logic)
