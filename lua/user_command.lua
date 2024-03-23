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


	local cur_pos = vim.api.nvim_win_get_cursor(0)
	local reg = args.reg == "" and "*" or string.lower(args.reg)

	-- clear register.
	vim.cmd(string.format("let @%s = \"\"", reg))

	-- copy matches to reigster
	vim.cmd(string.format("let @%s = join(hits, \"\\n\")", reg))

	-- back to position.
	vim.api.nvim_win_set_cursor(0, cur_pos)
end
vim.api.nvim_create_user_command("CopyMatches", CopyMatches, { register=true, range="%"})
vim.api.nvim_create_user_command("CM", CopyMatches, { register=true, range="%"})
