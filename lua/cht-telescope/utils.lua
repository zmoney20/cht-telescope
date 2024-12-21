local M = {}

--- write to debug.log
--- @param text string: The command to log
M.debug = function(text)
	local file = io.open("debug.log", "a")
	if file then
		file:write(text .. "\n")
		file:close()
	end
end

--- Merge user options with default options
--- @param default_opts Options: Default options
--- @param opts Options: Options to merge with default_opts
--- @return Options: Merged options
M.merge_opts = function(default_opts, opts)
	opts = opts or {}
	for k, v in pairs(default_opts) do
		if opts[k] == nil then
			opts[k] = v
		end
	end
	return opts
end

--- Generate the command to fetch cheat sheet topics
--- @param base_url string: Base URL for the cheat sheet
--- @param prompt string: User input for filtering results
--- @param opts Options: Options for filtering results
--- @return string: Generated command
M.generate_command = function(base_url, prompt, opts)
	local cmd = "curl -s " .. base_url .. "/:list"

	-- Apply include patterns if present
	if opts.include and #opts.include > 0 then
		local include_pattern = table.concat(opts.include, "|")
		cmd = cmd .. " | rg -i " .. vim.fn.shellescape(include_pattern)
	-- Apply exclude patterns if include patterns are not present
	elseif opts.exclude and #opts.exclude > 0 then
		local exclude_pattern = table.concat(opts.exclude, "|")
		cmd = cmd .. " | rg -v " .. vim.fn.shellescape(exclude_pattern)
	end

	if prompt and prompt ~= "" then
		cmd = cmd .. " | rg -i " .. vim.fn.shellescape(prompt) .. " | sort"
	end
	return cmd
end

-- Define the sed command to remove ANSI color codes
M.sed_command = "sed 's/\\x1b\\[[0-9;]*m//g'"

return M
