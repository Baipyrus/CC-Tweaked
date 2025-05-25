---@class GitHub_Content
---@field url string
---@field name string
---@field path string
---@field type string
---@field download_url string

local ignored = { "downloadScripts.lua", "pastebin.lua" }
local repoURL = "https://api.github.com/repos/Baipyrus/CC-Tweaked/contents/"
print("Requesting content of repository:")

---@param url string
---@param dataOnly? boolean
---@return GitHub_Content[]|string
local function repo_content_request(url, dataOnly)
	local response, message = http.get(url)
	if response == nil then
		error("Repository content request failed: " .. message)
	end

	local data = response.readAll()
	response.close()

	if data == nil then
		error("No repository content data found!")
	end

	if dataOnly == true then
		return data
	end

	---@type GitHub_Content[]|nil
	local content = textutils.unserialiseJSON(data)
	if content == nil then
		error("Failed to unserialize content data!")
	end

	return content
end

local repoContent = repo_content_request(repoURL)
assert(type(repoContent) == "table", "Expected 'GitHub_Content[]' from request result!")
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

for _, file in ipairs(repoContent) do
	-- Scan subdirectory content
	if file.type == "dir" then
		local subDir = repo_content_request(file.url)
		assert(type(subDir) == "table", "Expected 'GitHub_Content[]' from request result!")

		-- Extend repo content by subdir children
		table.move(subDir, 1, #subDir, #repoContent + 1, repoContent)

		goto continue
	end

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

	local d = repo_content_request(file.download_url, true)
	assert(type(d) == "string", "Expected 'string' from request result!")

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
