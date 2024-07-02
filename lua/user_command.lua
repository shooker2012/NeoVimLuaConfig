vim.api.nvim_create_user_command('CopyFileName', function(arg_table)
    local p1
    if arg_table.args and arg_table.args ~= "" then
        p1 = arg_table.args
    else
        p1 = ":p"
    end
    local fileName = vim.fn.expand("%"..p1)
    vim.fn.setreg("*", fileName)
end, { nargs='*' })

-- Copy matches to register.
-- Search for a pattern, then enter :CopyMatches to copy all matches to the clipboard, or :CopyMatches x where x is any register to hold the result.
local CopyMatches = function(args)
	vim.cmd("let hits = []")
	if args.line1 == args.line2 then
		vim.cmd(args.line1.."s//\\=len(add(hits, submatch(0)))/gen")
	else
		vim.cmd(string.format("%d,%d%s", args.line1, args.line2, "s//\\=len(add(hits, submatch(0)))/gen"))
	end

	local ret = table.concat(vim.g.hits, "\n")

	local cur_pos = vim.api.nvim_win_get_cursor(0)

	-- copy matches to reigster
	local reg = args.reg == "" and "*" or string.lower(args.reg)
	vim.fn.setreg(reg, ret)

	-- back to position.
	vim.api.nvim_win_set_cursor(0, cur_pos)
end
vim.api.nvim_create_user_command("CopyMatches", CopyMatches, { register=true, range="%"})
vim.api.nvim_create_user_command("CM", CopyMatches, { register=true, range="%"})


-- Map Quick Window
local MapQuickFixWindow = function()
	vim.cmd("botright copen")
	vim.keymap.set("n", "t", "^<C-w>gF:Neotree reveal<CR>")
end
vim.api.nvim_create_user_command("Copen", MapQuickFixWindow, {})

-- Hex mode
vim.cmd([[
" Hex mode start.==========
" ex command for toggling hex mode - define mapping if desired
command -bar Hexmode call ToggleHex()

" helper function to toggle hex mode
function ToggleHex()
  " hex mode should be considered a read-only operation
  " save values for modified and read-only for restoration later,
  " and clear the read-only flag for now
  let l:modified=&mod
  let l:oldreadonly=&readonly
  let &readonly=0
  let l:oldmodifiable=&modifiable
  let &modifiable=1
  if !exists("b:editHex") || !b:editHex
    " save old options
    let b:oldft=&ft
    let b:oldbin=&bin
    " set new options
    setlocal binary " make sure it overrides any textwidth, etc.
    silent :e " this will reload the file without trickeries 
              "(DOS line endings will be shown entirely )
    let &ft="xxd"
    " set status
    let b:editHex=1
    " switch to hex editor
    %!xxd
  else
    " restore old options
    let &ft=b:oldft
    if !b:oldbin
      setlocal nobinary
    endif
    " set status
    let b:editHex=0
    " return to normal editing
    %!xxd -r
  endif
  " restore values for modified and read only state
  let &mod=l:modified
  let &readonly=l:oldreadonly
  let &modifiable=l:oldmodifiable
endfunction

" nnoremap <C-H> :Hexmode<CR>
" inoremap <C-H> <Esc>:Hexmode<CR>
" vnoremap <C-H> :<C-U>Hexmode<CR>
" Hex mode end.==========
]])

-- Set diagnostic severity
function SetDiagnosticSeverity(arg_table)
	-- Try get value.
	local get_func = loadstring("return "..arg_table.args)
	local s = get_func and get_func()
	if not s then s = tonumber(arg_table.args) end

	if not s or _G.sal_diagnostic_severity == s then
		return
	end
	_G.sal_diagnostic_severity = s

	local config = {
		underline = {severity = {min=_G.sal_diagnostic_severity}},
		-- signs = {severity = { min = vim.diagnostic.severity.ERROR, }},
	}
	vim.diagnostic.config(config)
end

local complete_func = function(arg_lead, cmd_line, cursor_pos)
	local candidates = {
    	"vim.diagnostic.severity.ERROR",
    	"vim.diagnostic.severity.WARN",
    	"vim.diagnostic.severity.INFO",
    	"vim.diagnostic.severity.HINT",
	}

	-- Sort
	for i, v in ipairs(candidates) do
		if v:lower():find(arg_lead:lower()) then
			if i ~= 0 then
				table.remove(candidates, i)
				table.insert(candidates, 1, v)
			end
			break
		end
	end

	return candidates
end

vim.api.nvim_create_user_command("SetDiagnosticSeverity", SetDiagnosticSeverity, 
	{nargs=1, complete=complete_func})
