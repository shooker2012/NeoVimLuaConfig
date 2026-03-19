local status_ok, mason = pcall(require, "mason")
local status_ok, mason_lspconfig = pcall(require, "mason-lspconfig")


--[[
It's important that you set up the plugins in the following order:
	mason.nvim
	mason-lspconfig.nvim
	Setup servers via lspconfig
]]


if mason then
	mason.setup()
end

local default_servers = {
	"lua_ls",
	"pyright",
	"rust_analyzer",
}

if mason_lspconfig then
	mason_lspconfig.setup({
		ensure_installed = default_servers,
	})
end

-- Setup global lsp config that is in handlers.setup().
local handlers = require("Plugins.lsp.handlers")
handlers.setup()