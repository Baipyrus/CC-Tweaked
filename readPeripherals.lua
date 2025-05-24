-- Reference (at 24.05.2025): https://pastebin.com/uigZcEsw

term.clear()
local sides = peripheral.getNames()
local linesPerPage = 16  -- Depending on monitor size
local allLines = {}

for _, side in ipairs(sides) do
  local pType = peripheral.getType(side)
  table.insert(allLines, "Peripheral: " .. side .. " (" .. pType .. ")")

  local methods = peripheral.getMethods(side)
  if methods then
    for _, m in ipairs(methods) do
      table.insert(allLines, "  - " .. m)
    end
  else
    table.insert(allLines, "  (no methods found)")
  end
end

local currentPage = 1
local totalPages = math.ceil(#allLines / linesPerPage)

while true do
  term.clear()
  term.setCursorPos(1, 1)
  print("Peripherals (Page " .. currentPage .. "/" .. totalPages .. ")")
  print("--------------------------------")

  local startLine = (currentPage - 1) * linesPerPage + 1
  local endLine = math.min(startLine + linesPerPage - 1, #allLines)
  for i = startLine, endLine do
    print(allLines[i])
  end

  print("\n[N] Next | [P] Previous | [Q] Quit")
  local event, key = os.pullEvent("key")

  if key == keys.q then
    break
  elseif key == keys.n and currentPage < totalPages then
    currentPage = currentPage + 1
  elseif key == keys.p and currentPage > 1 then
    currentPage = currentPage - 1
  end
end
