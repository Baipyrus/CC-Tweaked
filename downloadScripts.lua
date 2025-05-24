---@class GitHub_Content
---@field path string
---@field download_url string

local ignored = { "downloadScripts.lua", "pastebin.lua" }
local url = "https://api.github.com/repos/Baipyrus/CC-Tweaked/content/"
print("Requesting content of repository:")
print(url)

local response = http.get(url)
if response == nil then
	print("Repository content request failed!")
	os.exit()
end

local data = response.readAll()
response.close()

if data == nil then
	print("No repository content data found!")
	os.exit()
end

---@type GitHub_Content[]|nil
local content = textutils.unserialiseJSON(data)
if content == nil then
	print("Failed to unserialize content data!")
	os.exit()
end
print("Requesting files within repository:")

---@param s string
---@param suffix string
function string.endswith(s, suffix)
	return s:sub(-#suffix) == suffix
end

---Get the index of a string in a table or -1 otherwise
---@param tbl table
---@param item any
local function string_table_idx(tbl, item)
	for idx, v in ipairs(tbl) do
		if v == item then
			return idx
		end
	end

	return -1
end

for _, file in ipairs(content) do
	-- Ignore conditions for some files
	local wrong_ext = not file.path:endswith(".lua")
	local is_ignored = string_table_idx(ignored, file.path) ~= -1
	if wrong_ext or is_ignored then
		goto continue
	end

	-- Deleting existing file and feedback
	if fs.exists(file.path) then
		fs.delete(file.path)
		print("Overwriting existing file '" .. file.path .. "' ...")
	else
		print("Downloading file '" .. file.path .. "' ...")
	end

	-- Using 'assert' because of previously established connection
	local r = http.get(file.download_url)
	assert(r ~= nil, "Panic: Could not establish connection to get file " .. file.path)
	local d = r.readAll()
	r.close()
	assert(d ~= nil, "Panic: Could not read file " .. file.path)

	-- Try creating new file
	local f = fs.open(file.path, "w")
	if f == nil then
		print("Could not open file. Skipping ...")
		goto continue
	end

	-- Save new file
	f.write(d)
	f.close()

	::continue::
end
