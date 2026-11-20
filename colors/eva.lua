vim.cmd.source(vim.fn.fnameescape(vim.env.VIMRUNTIME .. "/colors/eva.vim"))

local function set(group, options)
	vim.api.nvim_set_hl(0, group, options)
end

set("Comment", { fg = "#A8A8A8", ctermfg = 248, italic = true })
set("Constant", { fg = "#C58CFF", ctermfg = 183, bold = true })
set("@comment", { link = "Comment" })
set("@comment.documentation", { link = "Comment" })
set("@lsp.type.comment", { link = "Comment" })
set("@constant", { link = "Constant" })
set("@constant.builtin", { link = "Constant" })
set("@lsp.type.enumMember", { link = "Constant" })
set("@lsp.type.parameter", { link = "Identifier" })
set("@function", { link = "Function" })
set("@function.call", { link = "Function" })
set("@function.method", { link = "Function" })
set("@lsp.type.method", { link = "Function" })
