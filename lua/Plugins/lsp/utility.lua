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
	vim.lsp.config(server_name, opts)
end

return M