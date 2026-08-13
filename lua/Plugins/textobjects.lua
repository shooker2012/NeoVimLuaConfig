local M = {}

-- Single source of truth for textobject mappings.
M.mappings = {
	{ key = "af", query = "@function.outer", group = "textobjects" },
	{ key = "if", query = "@function.inner", group = "textobjects" },
	{ key = "ac", query = "@class.outer", group = "textobjects" },
	{ key = "ic", query = "@class.inner", group = "textobjects" },
	{ key = "as", query = "@local.scope", group = "locals" },
}

function M.setup()
	local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
	if not ok then
		return
	end

	textobjects.setup({
		select = {
			lookahead = true,
			include_surrounding_whitespace = false,
		},
	})

	for _, mapping in ipairs(M.mappings) do
		vim.keymap.set({ "x", "o" }, mapping.key, function()
			require("nvim-treesitter-textobjects.select")
				.select_textobject(mapping.query, mapping.group)
		end, {
			remap = false,
			silent = true,
			desc = "Select " .. mapping.query,
		})
	end
end

return M
