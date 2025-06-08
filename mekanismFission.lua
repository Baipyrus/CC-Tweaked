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

local pd_main = PageDisplay()
pd_main.setup("M. Fission Reactor", {}, pageLines, lineCallbacks)
pd_main.display()
