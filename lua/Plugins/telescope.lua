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

vim.keymap.set({"n", "v"}, "<C-P>", c_p, keymap_opts)
vim.keymap.set({"n", "v"}, "<C-F>", c_f, keymap_opts)

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

telescope.setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    mappings = {
      i = {
        ["<M-N>"] = actions.cycle_history_next,
        ["<M-P>"] = actions.cycle_history_prev,

		["<C-F>"] = custom_actions.c_f,
		["<C-P>"] = custom_actions.c_p,

        ["<C-J>"] = actions.move_selection_next,
        ["<C-K>"] = actions.move_selection_previous,

        ["<C-C>"] = actions.close,

        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,

        ["<CR>"] = actions.select_default,
        ["<C-S>"] = actions.select_horizontal,
        ["<C-V>"] = actions.select_vertical,
        ["<C-T>"] = actions.select_tab,

        -- ["<C-U>"] = actions.preview_scrolling_up,
        -- ["<C-D>"] = actions.preview_scrolling_down,

        ["<PageUp>"] = actions.results_scrolling_up,
        ["<PageDown>"] = actions.results_scrolling_down,

        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-Q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-Q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-L>"] = actions.complete_tag,
        ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>

        ["<C-U>"] = custom_actions.clear_prompt,
      },

      n = {
        ["<C-C>"] = actions.close,
		["<C-F>"] = custom_actions.c_f,
		["<C-P>"] = custom_actions.c_p,

        ["<esc>"] = actions.close,
        ["<CR>"] = actions.select_default,
        ["<C-S>"] = actions.select_horizontal,
        ["<C-V>"] = actions.select_vertical,
        ["<C-T>"] = actions.select_tab,

        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-Q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-Q>"] = actions.send_selected_to_qflist + actions.open_qflist,

        ["j"] = actions.move_selection_next,
        ["k"] = actions.move_selection_previous,
        ["H"] = actions.move_to_top,
        ["M"] = actions.move_to_middle,
        ["L"] = actions.move_to_bottom,

        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,
        ["gg"] = actions.move_to_top,
        ["G"] = actions.move_to_bottom,

        ["<C-U>"] = actions.preview_scrolling_up,
        ["<C-D>"] = actions.preview_scrolling_down,

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
