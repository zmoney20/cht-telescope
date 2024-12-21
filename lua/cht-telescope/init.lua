-- Telescope dependencies
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

-- Utils
local utils = require("cht-telescope.utils") -- Utility functions for common tasks

local M = {} -- Module table to hold all public functions

--- Default options
--- @type Options
local default_options = {
	debounce = 100,
}

--- Setup function to set default options
--- @param opts Options: Options to merge with default_options
M.setup = function(opts)
	opts = utils.merge_opts(default_options, opts)
end

--- Create a finder for cheat sheets
--- @param base_url string: Base URL for the cheat sheet
--- @param opts Options: Options for the finder
--- @return table: Finder object
local function create_finder(base_url, opts)
	return finders.new_async_job({
		command_generator = function(prompt)
			return { "sh", "-c", utils.generate_command(base_url, prompt) }
		end,
		entry_maker = make_entry.gen_from_string(opts),
	})
end

-- Define the sed command to remove ANSI color codes
local sed_command = utils.sed_command

--- Create a new picker for cheat sheets
--- @param title string: Title for the picker
--- @param base_url string: Base URL for the cheat sheet
--- @param opts Options: Options for the picker
--- @param on_select function: Function to call on selection
local function create_picker(title, base_url, opts, on_select)
	local picker = pickers.new(opts, {
		debounce = opts.debounce,
		prompt_title = title,
		finder = create_finder(base_url, opts),
		previewer = previewers.new_termopen_previewer({
			get_command = function(entry)
				return { "sh", "-c", "curl -s " .. base_url .. "/" .. entry.value .. " | " .. sed_command }
			end,
		}),
		sorter = require("telescope.sorters").get_fuzzy_file(),
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
local search_cht_sh_query = function(opts, topic)
	opts = utils.merge_opts(default_options, opts)

	create_picker("Cheat Sheets for " .. topic, "cht.sh/" .. topic, opts, function(selection)
		vim.cmd("new")
		vim.fn.termopen("curl -s cht.sh/" .. topic .. "/" .. selection.value .. " | " .. sed_command)
	end)
end

--- Search cheat sheet topics
--- @param opts Options: Options for the search
M.search_cht_sh = function(opts)
	opts = utils.merge_opts(default_options, opts)

	create_picker("Cheat Sheet Topics", "cht.sh", opts, function(selection)
		search_cht_sh_query(opts, selection.value)
	end)
end

return M
