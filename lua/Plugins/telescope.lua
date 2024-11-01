local status, telescope = pcall(require, "telescope")
if not telescope then return end

-- keymaps
local keymap_opts = {remap = false, silent = true}

local function c_p()
	local opts = require('telescope.themes').get_dropdown({ previewer = false })
	opts.find_by_full_path_words = false
	require'telescope.builtin'.find_files(opts)
end
local function c_f()
	telescope.extensions.live_grep_args.live_grep_args()
end
local function c_b()
	local opts = require('telescope.themes').get_dropdown({ previewer = false })
	opts.show_all_buffers = false
	-- opts.sort_mru = true
	opts.sort_buffers = function(a, b)
		local info_a = vim.fn.getbufinfo(a)[1]
		local info_b = vim.fn.getbufinfo(b)[1]

		if info_a.hidden < info_b.hidden then return true end
		return info_a.lastused > info_b.lastused
	end
	require'telescope.builtin'.buffers(opts)
end

vim.keymap.set({"n", "v"}, "<C-p>", c_p, keymap_opts)
vim.keymap.set({"n", "v"}, "<C-f>", c_f, keymap_opts)
vim.keymap.set({"n", "v"}, "<C-b>", c_b, keymap_opts)

local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
vim.keymap.set("n", "<F3>", function() live_grep_args_shortcuts.grep_word_under_cursor() end, keymap_opts)
vim.keymap.set("v", "<F3>", function() live_grep_args_shortcuts.grep_visual_selection() end, keymap_opts)




local actions = require "telescope.actions"

-- for utility functions
local action_state = require "telescope.actions.state"

local custom_actions = {}
custom_actions.clear_prompt = function(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
	current_picker:set_prompt("")
	-- local entry = action_state.get_selected_entry()
end

custom_actions.c_f = function(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
	local prompt = current_picker:_get_prompt()
	telescope.extensions.live_grep_args.live_grep_args({default_text = prompt})
end

custom_actions.c_p = function(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
	local prompt = current_picker:_get_prompt()

	local opts = require('telescope.themes').get_dropdown({ previewer = false })
	opts.find_by_full_path_words = false
	opts.default_text = prompt
	require'telescope.builtin'.find_files(opts)
end

custom_actions.c_b = function(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
	local prompt = current_picker:_get_prompt()

	local opts = require('telescope.themes').get_dropdown({ previewer = false })
	opts.show_all_buffers = false
	opts.sort_mru = true
	opts.default_text = prompt
	require'telescope.builtin'.buffers(opts)
end

custom_actions.c_cr = function(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
	if current_picker.prompt_title == "Buffers" then
		local entry = action_state.get_selected_entry()

		if entry then
			local info = vim.fn.getbufinfo(entry.bufnr)[1]
			if info and info.hidden == 0 and info.name ~= "" then
				vim.cmd.drop(entry.filename)
			else
				actions.select_default(prompt_bufnr)
			end
		end
	else
		actions.select_default(prompt_bufnr)
	end
end

telescope.setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    mappings = {
      i = {
        ["<M-n>"] = actions.cycle_history_next,
        ["<M-p>"] = actions.cycle_history_prev,

		["<C-f>"] = custom_actions.c_f,
		["<C-p>"] = custom_actions.c_p,
		["<C-b>"] = custom_actions.c_b,

        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,

        ["<C-c>"] = actions.close,

        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,

        ["<CR>"] = custom_actions.c_cr,
        ["<C-s>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,

        -- ["<C-u>"] = actions.preview_scrolling_up,
        -- ["<C-d>"] = actions.preview_scrolling_down,

        ["<PageUp>"] = actions.results_scrolling_up,
        ["<PageDown>"] = actions.results_scrolling_down,

        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-l>"] = actions.complete_tag,
        ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>

        ["<C-u>"] = custom_actions.clear_prompt,
      },

      n = {
        ["<C-c>"] = actions.close,
		["<C-f>"] = custom_actions.c_f,
		["<C-p>"] = custom_actions.c_p,
		["<C-b>"] = custom_actions.c_b,

        ["<esc>"] = actions.close,
        ["<CR>"] = custom_actions.c_cr,
        ["<C-s>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,

        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

        ["j"] = actions.move_selection_next,
        ["k"] = actions.move_selection_previous,
        ["H"] = actions.move_to_top,
        ["M"] = actions.move_to_middle,
        ["L"] = actions.move_to_bottom,

        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,
        ["gg"] = actions.move_to_top,
        ["G"] = actions.move_to_bottom,

        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,

        ["<PageUp>"] = actions.results_scrolling_up,
        ["<PageDown>"] = actions.results_scrolling_down,

        ["?"] = actions.which_key,
      },
    },

	default_mappings = {
	},

	vimgrep_arguments = {
		"rg",
		"--color=never",
		"--no-heading",
		"--with-filename",
		"--line-number",
		"--column",
		-- "--smart-case"
	},
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  extensions = {
	  --[[
	  ["zf-native"] = {
		  -- options for sorting file-like items
		  file = {
			  -- override default telescope file sorter
			  enable = true,

			  -- highlight matching text in results
			  highlight_results = true,

			  -- enable zf filename match priority
			  match_filename = true,

			  -- optional function to define a sort order when the query is empty
			  initial_sort = nil,
		  },

		  -- options for sorting all other items
		  generic = {
			  -- override default telescope generic item sorter
			  enable = true,

			  -- highlight matching text in results
			  highlight_results = true,

			  -- disable zf filename match priority
			  match_filename = false,

			  -- optional function to define a sort order when the query is empty
			  initial_sort = nil,
		  },
	  }
	  --]]
  },
}

telescope.load_extension("live_grep_args")
telescope.load_extension("zf-native")
