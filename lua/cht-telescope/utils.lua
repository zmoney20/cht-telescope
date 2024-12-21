local M = {}

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
--- @return string: Generated command
M.generate_command = function(base_url, prompt)
	local cmd = "curl -s " .. base_url .. "/:list | rg -v '^:' | rg -v '^\\['"
	if prompt and prompt ~= "" then
		cmd = cmd .. " | rg -i " .. vim.fn.shellescape(prompt) .. " | sort"
	end
	return cmd
end

-- Define the sed command to remove ANSI color codes
M.sed_command = "sed 's/\\x1b\\[[0-9;]*m//g'"

return M
