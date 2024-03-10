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
    'nvim-lua/plenary.nvim',
    'nvim-lua/popup.nvim',

    -- New auto pairs.
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true
        -- use opts = {} for passing setup options
        -- this is equalent to setup({}) function
    },

    -- nvim-cmp
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',   -- { name = 'buffer' },
    'hrsh7th/cmp-path',     -- { name = 'path' }
    'hrsh7th/cmp-cmdline',  -- { name = 'cmdline' }
    'hrsh7th/nvim-cmp',

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
        'smoka7/hop.nvim',
        tag = '*',
        opts = {},
        config = function(plugin, opts)
            require'hop'.setup(opts)
           
            vim.keymap.set('', 's', function()
                require('hop').hint_char2()
            end, {remap=true})
        end,
    },
}

opts = nil

require("lazy").setup(plugins, opts)