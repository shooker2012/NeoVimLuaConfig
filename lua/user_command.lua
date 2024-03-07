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
