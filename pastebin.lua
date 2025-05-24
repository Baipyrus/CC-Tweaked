local filename = "downloadScripts.lua"
local url = "https://raw.githubusercontent.com/Baipyrus/CC-Tweaked/main/" .. filename

-- Request download script from GitHub
local response = http.get(url)
if response == nil then
	print("Download repository request failed!")
	os.exit()
end

local data = response.readAll()
response.close()

if data == nil then
	print("Download script not found!")
	os.exit()
end

-- Deleting existing file
if fs.exists(filename) then
	fs.delete(filename)
end

-- Try creating new file
local f = fs.open(filename, "w")
if f == nil then
	print("Could not open file!")
	os.exit()
end

-- Save new file
f.write(data)
f.close()

-- Run download script
shell.run(filename:sub(0, -5))
