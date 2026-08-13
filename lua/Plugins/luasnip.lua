local M = {}

function M.setup()
	local luasnip = require("luasnip")

	luasnip.config.setup({
		keep_roots = true,
		link_roots = true,
		link_children = true,
		exit_roots = false,
		update_events = { "TextChanged", "TextChangedI" },
		delete_check_events = { "TextChanged", "TextChangedI" },
		cut_selection_keys = "<Tab>",
	})

	local snippet_path = vim.fn.fnamemodify(vim.env.MYVIMRC, ":p:h") .. "/luasnippets"
	require("luasnip.loaders.from_lua").lazy_load({ paths = { snippet_path } })
end

return M
