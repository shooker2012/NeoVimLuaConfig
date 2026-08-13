-- Use lazy.nvim to manage plugins.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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
	-- LSP
	{
		"williamboman/mason.nvim",
		cmd = {
			"Mason",
			"MasonInstall",
			"MasonUninstall",
			"MasonUninstallAll",
			"MasonUpdate",
			"MasonLog",
		},
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "pyright", "rust_analyzer" },
				automatic_enable = false,
			})
		end,
	},
	"neovim/nvim-lspconfig",


	-- nvim-cmp
	-- "saadparwaiz1/cmp_luasnip",
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"quangnguyen30192/cmp-nvim-ultisnips",
		},
		config = function(plugin, opts)
			require "Plugins.nvim-cmp"
		end,
	},
	{
		"stevearc/conform.nvim",
		cmd = "ConformInfo",
		init = function()
			require("Plugins.conform").register_command()
		end,
		config = function()
			require("Plugins.conform").setup()
		end,
	},


	-- vim-matchup
	{
		"andymass/vim-matchup",
		-- Load before the initial FileType event. Loading on VimEnter misses the
		-- first file passed on the command line, leaving that buffer uninitialized.
		lazy = false,
		init = function()
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
			vim.g.matchup_treesitter_enabled = 1
			vim.g.matchup_treesitter_disabled = { "c", "ruby" }
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
		keys = { { "s", mode = "" } },
		-- version = "*",
		opts = {
			case_insensitive = true
		},
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
		event = "VeryLazy",
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
		keys = {
			{ "<C-p>", mode = { "n", "v" } },
			{ "<C-f>", mode = { "n", "v" } },
			{ "<C-b>", mode = { "n", "v" } },
			{ "<F3>", mode = { "n", "v" } },
		},
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
		branch = "main",
		config = function()
			require("Plugins.treesitter").setup()
		end,
	},

	-- Treesitter Extentions
	-- "nvim-treesitter/nvim-treesitter-textobjects",
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		init = function()
			-- Disable entire built-in ftplugin mappings to avoid conflicts.
			-- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
			vim.g.no_plugin_maps = true

			-- Or, disable per filetype (add as you like)
			-- vim.g.no_python_maps = true
			-- vim.g.no_ruby_maps = true
			-- vim.g.no_rust_maps = true
			-- vim.g.no_go_maps = true
		end,
		config = function()
			require("Plugins.textobjects").setup()
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "VeryLazy",
		opts = {
			enable = true,
			max_lines = 0,
			mode = "cursor",
		},
	},

	-- aerial.nvim
	{
		"stevearc/aerial.nvim",
		keys = { "<F4>", "<S-F4>" },
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

	-- ============================================================Vimscript Plugins============================================================
	{ "godlygeek/tabular", event = "VeryLazy" },    -- Tabular
	{ "tommcdo/vim-exchange", event = "VeryLazy" }, -- vim exchange
	{ "tpope/vim-abolish", event = "VeryLazy" },    -- vim abolish

	-- vim mark
	{
		"inkarkat/vim-mark",
		event = "VeryLazy",
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

require("lazy").setup(plugins, { rocks = { enabled = false } })

require("Plugins.lsp.lsp").setup()
