local filename = "util/downloadScripts.lua"
local url = "https://raw.githubusercontent.com/Baipyrus/CC-Tweaked/main/" .. filename

-- Request download script from GitHub
local response, message = http.get(url)
if response == nil then
	error("Repository content request failed: " .. message)
end

local data = response.readAll()
response.close()

if data == nil then
	error("Download script not found!")
end

-- Deleting existing file
if fs.exists(filename) then
	fs.delete(filename)
end

-- Try creating new file
local f = fs.open(filename, "w")
if f == nil then
	error("Could not open file!")
end

-- Save new file
f.write(data)
f.close()

-- Run download script
shell.run(filename:sub(0, -5))
