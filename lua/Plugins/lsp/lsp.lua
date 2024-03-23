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

if mason_lspconfig then
	mason_lspconfig.setup()
end

-- Setup global lsp config that is in handlers.setup().
local handlers = require("Plugins.lsp.handlers")
handlers.setup()


if lspconfig then

	-- All installed servers. Can custom opts by create optional file "Plugins/lsp/settings/[server_name].lua".
	local servers = {
		"lua_ls",
		"pyright",
		"rust_analyzer",
	}

	for _, server in pairs(servers) do
		local opts = {
			on_attach = handlers.on_attach,
			capabilities = handlers.capabilities,
		}

		server = vim.split(server, "@")[1]

		local require_ok, conf_opts = pcall(require, "Plugins.lsp.settings." .. server)
		if require_ok then
			opts = vim.tbl_deep_extend("force", conf_opts, opts)
		end

		lspconfig[server].setup(opts)
	end
end