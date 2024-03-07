-- to copy and pase
local opts = {remap = false, silent = true}

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

-- map F5 to create a new tab and open currentfile and mirror NERDTREE
vim.keymap.set('n', '<F5>', function()
    io.popen("ctags -R .")
    vim.cmd("UpdateTypesFile")
end, opts)

-- map F9 to create a new tab and open currentfile and mirror NERDTREE
vim.keymap.set('n', '<F9>', function()
    vim.cmd("tabe %")
    vim.cmd(":NERDTreeFind")
    vim.cmd.normal(vim.api.nvim_replace_termcodes("<C-W>l", true, true, true))
end, opts)

-- map F10 to open current file's folder
vim.keymap.set({'n', 'v'}, '<F10>', function() 
    --io.popen("start explorer.exe /select,"..vim.api.nvim_call_function('expand', {"%:p"}))
    io.popen("start explorer.exe /select,"..vim.fn.expand("%:p"))
end, opts)

vim.keymap.set('n', 'F11', function()
    local fileName = vim.fn.expand("%:p")
end, opts)

-- map [t and ]t: jump to parent tag
vim.keymap.set('n', ']t', 'vatatv', opts)
vim.keymap.set('n', '[t', 'vatatov', opts)

-- map vP to select changed area.
vim.keymap.set('n', 'vP', '`[v`]', opts)
vim.keymap.set('n', 'v<C-P>', '`[<C-V>`]', opts)

