-- Telescope dependencies
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")

-- Utils
local utils = require("cht-telescope.utils")

local M = {}

--- @type Options
local default_opts = {
	debounce = 100,
	include = {},
	exclude = {},
}

--- @type Options
local merged_opts = {}

--- Setup function to set default options
--- @param opts? Options: Options to merge with default_opts
M.setup = function(opts)
	opts = opts or {}
	merged_opts = utils.merge_opts(default_opts, opts)
end

--- Create a finder for cheat sheets
--- @param base_url string: Base URL for the cheat sheet
local create_finder = function(base_url)
	return finders.new_async_job({
		--- @param prompt string
		--- @return Command
		command_generator = function(prompt)
			return { "sh", "-c", utils.generate_command(base_url, prompt, merged_opts) }
		end,
		entry_maker = make_entry.gen_from_string(merged_opts),
	})
end

--- Create a new picker for cheat sheets
--- @param title string: Title for the picker
--- @param base_url string: Base URL for the cheat sheet
--- @param on_select function: Function to call on selection
local create_picker = function(title, base_url, on_select)
	local picker = pickers.new(merged_opts, {
		debounce = merged_opts.debounce,
		prompt_title = title,
		finder = create_finder(base_url),
		previewer = previewers.new_buffer_previewer({
			define_preview = function(self, entry)
				local cmd = "curl -s " .. base_url .. "/" .. entry.value .. " | " .. utils.sed_command
				local output = vim.fn.system(cmd)
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(output, "\n"))
				-- Set the filetype for syntax highlighting
				local filetype = "sh" -- Default filetype
				if base_url:match("cht.sh/") then
					local topic = base_url:match("cht.sh/(.+)")
					if topic then
						filetype = topic
					end
				end
				vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", filetype)
			end,
		}),
		sorter = sorters.get_fuzzy_file(),
	})

	local original_select_default = actions.select_default

	actions.select_default:replace(function(prompt_bufnr)
		local selection = action_state.get_selected_entry()
		if selection then
			actions.close(prompt_bufnr)
			on_select(selection)
			actions.select_default = original_select_default
		end
	end)

	picker:find()
end

--- Search cheat sheets for a specific topic
--- @param opts Options: Options for the search
--- @param topic string: The topic to search for
local search_cht_sh_query = function(topic, opts)
	opts = utils.merge_opts(merged_opts, opts)

	-- Check if the topic has a list of cheat sheets
	local topic_list = "curl -s cht.sh/" .. topic .. "/:list | " .. utils.sed_command
	local list_output = vim.fn.system(topic_list)

	-- If the topic has no list of cheat sheets, open the cheat sheet
	if not list_output or list_output == "" or list_output == "\n" then
		local buffer_topic = "curl -s cht.sh/" .. topic .. " | " .. utils.sed_command
		local buffer_output = vim.fn.system(buffer_topic)
		utils.create_buffer(buffer_topic, buffer_output, false)
		return
	end

	-- If the topic has a list of cheat sheets, create a picker for the list of cheat sheets
	create_picker("Cheat Sheets for " .. topic, "cht.sh/" .. topic, function(selection)
		local cmd = "curl -s cht.sh/" .. topic .. "/" .. selection.value .. " | " .. utils.sed_command
		local output = vim.fn.system(cmd)
		utils.create_buffer(topic, output, true)
	end)
end

--- Search cheat sheet topics
--- @param opts Options: Options for the search
M.search_cht_sh = function(opts)
	opts = utils.merge_opts(merged_opts, opts)

	create_picker("Cheat Sheet Topics", "cht.sh", function(selection)
		search_cht_sh_query(selection.value, opts)
	end)
end

return M
