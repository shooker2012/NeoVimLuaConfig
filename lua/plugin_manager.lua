-- Use lazy.nvim to manage plugins.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
	"git",
	"clone",
	"--filter=blob:none",
	"https://github.com/folke/lazy.nvim.git",
	"--branch=stable", -- latest stable release
	lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	-- Underlying
	"nvim-lua/plenary.nvim",
	"nvim-lua/popup.nvim",

	-- New auto pairs.
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true
		-- use opts = {} for passing setup options
		-- this is equalent to setup({}) function
	},

	-- -- LuaSnip
	-- {
	-- 	"L3MON4D3/LuaSnip",
	-- 	-- follow latest release.
	-- 	--version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	-- 	config = function(plugin, opts)
	-- 		require("luasnip.loaders.from_snipmate").lazy_load()
	-- 	end,
	-- },

	-- UltiSnips
	{
		"SirVer/ultisnips",
		config = function(plugin, opts)
			local path = vim.fn.fnamemodify(vim.env.MYVIMRC, ":p:h").."/ultisnips"
			vim.g.UltiSnipsSnippetDirectories = {path}
		end,
	},
	"quangnguyen30192/cmp-nvim-ultisnips",

	-- LSP
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	"neovim/nvim-lspconfig",
	"jose-elias-alvarez/null-ls.nvim", -- LSP diagnostics and code actions


	-- nvim-cmp
	"hrsh7th/cmp-nvim-lsp",
  	"hrsh7th/cmp-nvim-lua",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	-- "saadparwaiz1/cmp_luasnip",
	{
		"hrsh7th/nvim-cmp",
		config = function(plugin, opts)
			require "Plugins.nvim-cmp"
		end,
	},


	-- vim-matchup
	{
		"andymass/vim-matchup",
		event = "VimEnter",
		config = function(plugin, opts)
		  vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},

	-- color scheme
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
		config = function(plugin, opts)
			vim.cmd("colorscheme tokyonight-moon")
		end,
	},

	-- hop.nvim. supplant easy-motion.
	{
		"smoka7/hop.nvim",
		version = "*",
		opts = {},
		config = function(plugin, opts)
			require"hop".setup(opts)

			vim.keymap.set("", "s", function()
				require("hop").hint_char2()
			end, {remap=true})
		end,

		--[[修改代码：使jump时永远ignore case.
		--hop.nvim\lua\hop\jump_regex.lua
		-- function M.regex_by_case_searching(pat, plain_search, opts)
		--	-    if vim.o.smartcase and not starts_with_uppercase(pat) then
		--	+    if not starts_with_uppercase(pat) then
		-- 
		--]]
	},

	-- Comment
	{
		"numToStr/Comment.nvim",
		opts = {},
		lazy = false,
	},

	-- Surround
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({ })
		end
	},

	-- Neo-tree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},

		config = function(plugin, opts)
			require("Plugins.neo-tree")
		end,
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function(plugin, opts)
			require("lualine").setup({
				sections = {
					lualine_a = {"mode"},
					lualine_b = {"filename"},
					lualine_c = {"encoding", "fileformat", "filetype"},
					lualine_x = {"progress"},
					lualine_y = {"location"},
					lualine_z = {"branch", "diff", "diagnostics"},
				},
			})
		end,
	},

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",

		opts = { rocks = {enabled = false}},
		dependencies = {
			{ 
				"nvim-telescope/telescope-live-grep-args.nvim" ,
				-- -- This will not install any breaking changes.
				-- -- For major updates, this must be adjusted manually.
				version = "^1.0.0",
			},

			{
				"natecraddock/telescope-zf-native.nvim",
			},
		},

		config = function(plugins, opts)
			require("Plugins.telescope")
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		config = function(plugins, opts)
			require("Plugins.treesitter")
		end,
	},

	-- Treesitter Extentions
	"nvim-treesitter/nvim-treesitter-textobjects",
	"nvim-treesitter/nvim-treesitter-context",

	-- vim-matchup
	"andymass/vim-matchup",

	-- aerial.nvim
	{
		"stevearc/aerial.nvim",
		config = function(plugins, opts)
			local aerial = require("aerial")
			aerial.setup({
				layout = {
					max_width = {0.4}
				},
				
				-- Disable aerial on fiels with this many lines.
				disable_max_lines = 50000,
			})

			local config = require("aerial.config")
			-- keymap
			vim.keymap.set("n", "<F4>", function()
				config.close_on_select = true
				aerial.toggle()
			end, {remap = false, silent = true})
			vim.keymap.set("n", "<S-F4>", function()
				config.close_on_select = false
				aerial.toggle()
			end, {remap = false, silent = true})
		end,
	},

	-- Sal-proj
	{
		"shooker2012/sal-proj-lua",
		config = function(plugins, opts)
			require("sal-proj-lua")
		end,
	},

	-- Sal-Custom-Macro
	{
		"shooker2012/sal-custom-macro",
		config = function(plugins, opts)
			require("sal-custom-macro")
		end,
	},

	-- Copilot
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				-- suggestion = { enabled = false },

				-- use default
				-- suggestion = {
				-- 	enabled = true,
				-- 	auto_trigger = true,
				-- 	hide_during_completion = true,
				-- 	debounce = 75,
				-- 	keymap = {
				-- 		accept = "<M-l>",
				-- 		accept_word = false,
				-- 		accept_line = false,
				-- 		next = "<M-]>",
				-- 		prev = "<M-[>",
				-- 		dismiss = "<C-]>",
				-- 	},
				-- },

				panel = { enabled = false },
			})
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		config = function ()
			require("copilot_cmp").setup()
		end

	},
	-- Copilot chat,
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		opts = {
			-- See Configuration section for options
			prompts = {
				DebugRunPath = {
					-- prompt = 'warning all run path and relevant value with prefix "~~~~~~~~~~debug: "',
					prompt = '在所有执行路径中添加 `warn()` 函数作为 debug log。在分支路径前输出决定分支的变量及其表达式，前缀为 "\\~\\~\\~\\~\\~\\~\\~\\~\\~\\~debug: [%相关环境名%] "，并且在前缀后加入与分支代码层级相应的缩进。这有助于在调试时更清晰地了解代码的执行路径和变量的状态。一个分支所有的变量，应该在一行log中。',
					-- system_prompt = 'You are very good at explaining stuff',
					-- mapping = '<leader>ccmc',
					-- description = 'My custom prompt description',
				},
			},
		},
		config = function(plugins, opts)
			require("CopilotChat").setup(opts)
			vim.cmd.cnoreabbrev("CC CopilotChat")
		end
	},

	-- ============================================================Vimscript Plugins============================================================
	"godlygeek/tabular",    -- Tabular
	"tommcdo/vim-exchange", -- vim exchange
	"tpope/vim-abolish",    -- vim abolish

	-- vim mark
	{
		"inkarkat/vim-mark",
		dependencies = {
			"inkarkat/vim-ingo-library",
		},
	},

	-- -- [Profile]
	-- "stevearc/profile.nvim",
}

-- ============================================================Vimscript Plugins Configs============================================================
vim.cmd([[
"[plugin]mark
nmap <Plug>IgnoreMarkSearchNext <Plug>MarkSearchNext
nmap <Plug>IgnoreMarkSearchPrev <Plug>MarkSearchPrev

nnoremap <silent> <C-l> :<C-u>nohlsearch<CR>:<C-u>MarkClear<CR><C-l>
nnoremap <silent> <C-k> :<C-u>Mark<CR>
]])

opts = { rocks = { enabled = false } }

require("lazy").setup(plugins, opts)

require("Plugins.lsp.lsp")
