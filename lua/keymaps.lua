-- to copy and pase
local opts = {remap = false, silent = true}

 -- search and hightlight, but not move the next matching
vim.keymap.set('n', '*', '*N', opts)

vim.cmd([[
function! s:VSetSearch()
	let temp = @s
	norm! gv"sy
	let @/ = '\V' . substitute(escape(@s, '/\'), '\n', '\\n', 'g')
	let @s = temp
endfunction

" In visual mode, map* and # to search current selected.
xnoremap * :<C-u>call <SID>VSetSearch()<CR>/<C-R>=@/<CR><CR>N
xnoremap # :<C-u>call <SID>VSetSearch()<CR>?<C-R>=@/<CR><CR>

]])

local function search_visual_selection()
	local start = vim.fn.getpos("'<")
	local finish = vim.fn.getpos("'>")
	if start[2] > finish[2] or (start[2] == finish[2] and start[3] > finish[3]) then
		start, finish = finish, start
	end
	local start_row, start_col = start[2] - 1, start[3] - 1
	local end_row, end_col = finish[2] - 1, finish[3]
	local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
	if #lines == 0 then
		return
	end
	local literal = vim.fn.escape(table.concat(lines, "\n"), "\\")
	literal = literal:gsub("\n", "\\n")
	local regex = "\\V" .. literal
	vim.fn.setreg("/", regex)
	require("vimgrepbuffer").search(regex, { jump = false })
end

vim.keymap.set("n", "<F2>", function()
	require("vimgrepbuffer").vimgrep_buffer("//j", { jump = false })
end, { silent = true, desc = "Repeat search in quickfix" })

vim.keymap.set("x", "<F2>", function()
	search_visual_selection()
end, { silent = true, desc = "Search selection in quickfix" })

vim.keymap.set('n', ',', '"0', opts)
vim.keymap.set('v', ',', '"0', opts)
vim.keymap.set('n', '_', ',', opts)
vim.keymap.set('v', '_', ',', opts)
vim.keymap.set('n', '<Leader>p', '"*p', opts)
vim.keymap.set('v', '<Leader>p', '"*p', opts)
vim.keymap.set('n', '<Leader>y', '"*y', opts)
vim.keymap.set('v', '<Leader>y', '"*y', opts)
vim.keymap.set('n', '<Leader>d', '"*d', opts)
vim.keymap.set('v', '<Leader>d', '"*d', opts)
vim.keymap.set('n', '<Leader>P', '"*P', opts)
vim.keymap.set('v', '<Leader>P', '"*P', opts)
vim.keymap.set('n', '<Leader>Y', '"*Y', opts)
vim.keymap.set('v', '<Leader>Y', '"*Y', opts)
vim.keymap.set('n', '<Leader>D', '"*D', opts)
vim.keymap.set('v', '<Leader>D', '"*D', opts)

-- map F5 to clear all swap files.
vim.keymap.set('n', '<F5>', function()
	local swap_folder = vim.fn.fnamemodify(vim.fn.swapname(""), ":p:r")

	-- Get all files and directories in CWD
	local swap_files = vim.split(vim.fn.glob( swap_folder..".*"), '\n', {trimempty=true})

	-- Check if specified file or directory exists
	for _, file_name in pairs(swap_files) do
		print("Clear swap file:", file_name)
		os.remove(file_name)
	end

end, opts)

-- map F9 to create a new tab and open currentfile and mirror NERDTREE
vim.keymap.set('n', '<F9>', function()
    vim.cmd("tabe %")
    vim.cmd(":Neotree reveal")
    vim.cmd.normal(vim.api.nvim_replace_termcodes("<C-W>l", true, true, true))
end, opts)

-- map F10 to open current file's folder
vim.keymap.set({'n', 'v'}, '<F10>', function()
    io.popen("start explorer.exe /select,"..vim.fn.expand("%:p"))
end, opts)

-- map [t and ]t: jump to parent tag
vim.keymap.set('n', ']t', 'vatatv', opts)
vim.keymap.set('n', '[t', 'vatatov', opts)

-- map vP to select changed area.
vim.keymap.set('n', 'vP', '`[v`]', opts)
vim.keymap.set('n', 'v<C-P>', '`[<C-V>`]', opts)

-- Diagnostics
vim.keymap.set({'n', 'v'}, '[d', function()
	vim.diagnostic.jump({ count = -1, float = true, severity = { min = _G.sal_diagnostic_severity } })
end, opts)
vim.keymap.set({'n', 'v'}, ']d', function()
	vim.diagnostic.jump({ count = 1, float = true, severity = { min = _G.sal_diagnostic_severity } })
end, opts)

vim.keymap.set('n', '<Leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<Leader>q', vim.diagnostic.setloclist, opts)

-- map ctrl-r + register not auto-indent in insert mode
vim.keymap.set('i', '<C-R>', '<C-R><C-O>', opts)
vim.keymap.set('i', '<C-R><C-O>', '<C-R>', opts)
