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

M.create_buffer = function(topic, output, is_language)
	-- Create a new split window
	vim.cmd("new")

	-- Split the output into lines
	local lines = vim.split(output, "\n")

	-- Set the buffer lines
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

	-- Set the filetype for syntax highlighting
	if not is_language then
		topic = "sh" -- Default filetype
	end
	vim.api.nvim_buf_set_option(0, "filetype", topic)

	-- Make the buffer read-only
	vim.api.nvim_buf_set_option(0, "modifiable", false)
	vim.api.nvim_buf_set_option(0, "readonly", true)
	-- Set buffer options to avoid save prompts
	vim.api.nvim_buf_set_option(0, "buftype", "nofile")
	vim.api.nvim_buf_set_option(0, "bufhidden", "wipe")
end

-- Define the sed command to remove ANSI color codes
M.sed_command = "sed 's/\\x1b\\[[0-9;]*m//g'"

return M
