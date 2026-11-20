vim.cmd.source(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/colors/eva.lua"))

local function set(group, options)
	vim.api.nvim_set_hl(0, group, options)
end

set("Normal", { fg = "#EEEEEE", bg = "#202124", ctermfg = 255, ctermbg = 234 })
set("CursorLine", { bg = "#292B2E", ctermbg = 235 })
set("LineNr", { fg = "#A3A6A8", ctermfg = 249 })
set("Comment", { fg = "#A8A8A8", ctermfg = 248, italic = true })

for _, group in ipairs({
	"Constant", "Identifier", "Statement", "PreProc", "Type", "Special",
	"Regexp", "Function", "Operator", "Delimiter",
}) do
	local current = vim.api.nvim_get_hl(0, { name = group, link = false })
	current.bold = false
	vim.api.nvim_set_hl(0, group, current)
end
