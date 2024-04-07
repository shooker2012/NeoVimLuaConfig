return {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
				disable = { "invisible", },
			},

			workspace = {
				preloadFileSize = 1000,
				--			library = {
					--				[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					--				[vim.fn.stdpath("config") .. "/lua"] = true,
					--			},
			},
		},
	},
}
