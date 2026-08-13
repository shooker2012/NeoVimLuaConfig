local M = {}

M.servers = {
	"lua_ls",
	"pyright",
	"rust_analyzer",
}

local function prepend_mason_bin()
	local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
	if not vim.uv.fs_stat(mason_bin) then
		return
	end

	local path = vim.env.PATH or ""
	local separator = vim.fn.has("win32") == 1 and ";" or ":"
	if path == mason_bin or vim.startswith(path, mason_bin .. separator) then
		return
	end

	vim.env.PATH = mason_bin .. (path == "" and "" or separator .. path)
end

function M.setup()
	prepend_mason_bin()
	require("Plugins.lsp.handlers").setup()
	vim.lsp.enable(M.servers)
end

return M
