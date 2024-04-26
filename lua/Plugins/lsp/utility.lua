local M = {}

-- Extend configs for lsp server.
-- [Sampel]
--[[
	require("Plugins.lsp.utility").setup_extend("lua_ls", { 
		settings = {
			Lua = {
				workspace = {
					ignoreDir = { "/Configs", }
				}
			},

			diagnostics = {
				ignoredFiles = "Disable"
			},
		}
	})
--]]
-- 
M.setup_extend = function(server_name, opts)
	local server = require("lspconfig")[server_name]
	if not server then return end

	local cache = server.config_cache or {}
	opts = vim.tbl_deep_extend("force", cache, opts)

	server.setup(cache)
	server.config_cache = opts
end

return M