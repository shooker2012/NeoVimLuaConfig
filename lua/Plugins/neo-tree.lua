-- Set custom command which can:
-- 1. set noautodir
-- 2. can complete files and environment values.
local complete_func = function(arg_lead, cmd_line, cursor_pos)
	cmd_line = cmd_line:gsub("^NT", "Neotree")
	local condidate = {}
	local env_map = vim.fn.environ()
	if arg_lead:len() > 0 then
		for k, v in pairs(env_map) do
			local real_key = "$"..k
			if real_key:sub(1, arg_lead:len()) == arg_lead then
				table.insert(condidate, real_key)
			end
		end

		for i, v in ipairs(vim.fn.glob(arg_lead.."*", false, true)) do
			table.insert(condidate, v)
		end
	end

	local nt_args = require'neo-tree.command'.complete_args(arg_lead, cmd_line, cursor_pos)
	for i, v in ipairs(vim.fn.split(nt_args, "\n")) do
		if not vim.tbl_contains(condidate, v) then
			table.insert(condidate, v)
		end
	end

	return condidate
end

vim.api.nvim_create_user_command('NT', function(arg_table)
	local path = arg_table.fargs[1]
	if path and vim.fn.filereadable(path) > 0 then
		vim.cmd.edit(path)
	end

	local neotree_cmd = require("neo-tree.command")._command

	-- force add show
	if not vim.tbl_contains(arg_table.fargs, "show")
		and not vim.tbl_contains(arg_table.fargs, "close")
		and not vim.tbl_contains(arg_table.fargs, "focus") then
		table.insert(arg_table.fargs,  "show")
	end

	-- force add reveal_force_cwd.
	if not vim.tbl_contains(arg_table.fargs, "reveal_force_cwd") then
		table.insert(arg_table.fargs,  "reveal_force_cwd")
	end

	neotree_cmd(unpack(arg_table.fargs))

	vim.o.autochdir = false
end, { nargs='*', complete=complete_func})

