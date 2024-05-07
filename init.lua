vim.opt.backup = false
-- vim.opt.clipboard = "unnamedplus"					-- use system clipboard or not.
vim.opt.fixendofline = false                            -- disable to add a unwanted newline at the end of the file.

vim.opt.backspace = {"indent","eol","start"}            -- allow backspacing over everything in insert mode
vim.opt.ruler = true                                    -- show the cursor position all the time
vim.opt.showcmd = true                                  -- display incomplete commands
vim.opt.incsearch = true                                -- do incremental searching
vim.opt.hlsearch = true

vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

vim.opt.fileencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.termencoding = "utf-8"
vim.opt.fileencodings = {"utf-8","cp936","ucs-bom","shift-jis","latin1","big5","gb18030","gbk","gb2312"}

vim.opt.guifont="Consolas:h11"
vim.opt.guifontwide="NSimSun:h12"

vim.opt.mouse = "a"
vim.opt.termguicolors = true

vim.opt.jumpoptions = "stack"

vim.opt.listchars = { tab="■■",trail = "▓",eol="▼"}

vim.opt.autochdir = true

vim.opt.foldenable = false

--[[ Use neovide instead of the under codes.
-- Autoreolad when file changed.
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
	  command = "if mode() != 'c' | checktime | endif",
	    pattern = { "*" },
	})
--]]

-- Use this global value to control diagnostic goto_[prev/next] and underline.
_G.sal_diagnostic_severity = vim.diagnostic.severity.WARN

require "keymaps"

require "user_command"

-- set syntax rules for glsl and hlsl
vim.cmd('au BufNewFile,BufRead *.frag,*.vert,*.fp,*.vp,*.glsl,*.fsh,*.vsh setf glsl')
vim.cmd('au BufNewFile,BufRead *.hlsl,*.fx,*.fxh,*.vsh,*.psh,*.shader setf fx')

require "plugin_manager"

-- [Profile]
require("sal_profile")
