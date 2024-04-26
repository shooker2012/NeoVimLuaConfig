local status_ok, mason = pcall(require, "mason")
local status_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
local status_ok, lspconfig = pcall(require, "lspconfig")


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


local root = vim.fn.fnamemodify( os.getenv("MYVIMRC"), ':p:h' ).."/lua"
function file_exists(name)
	name = root.."/".. name:gsub("%.", "/")..".lua"
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

if lspconfig then
	-- All installed servers. Can custom opts by create optional file "Plugins/lsp/settings/[server_name].lua".

	for _, server in pairs(default_servers) do
		local opts = {
			on_attach = handlers.on_attach,
			capabilities = handlers.capabilities,
		}

		server = vim.split(server, "@")[1]

		local file_name = "Plugins.lsp.settings." .. server

		if file_exists(file_name) then
			local conf_opts = require(file_name)
			opts = vim.tbl_deep_extend("force", conf_opts, opts)
		end

		lspconfig[server].setup(opts)
		lspconfig[server].config_cache = opts
	end
end