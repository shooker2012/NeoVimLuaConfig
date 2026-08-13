local M = {}

-- Parser dependencies (c for glsl, cpp for hlsl) are resolved by
-- nvim-treesitter when the requested languages are normalized.
M.languages = {
	"c",
	"cpp",
	"lua",
	"rust",
	"python",
	"vim",
	"vimdoc",
	"query",
	"glsl",
	"hlsl",
	"markdown",
	"markdown_inline",
	"json",
	"bash",
}

-- Filetypes that map to parsers supplied by the language list above.
M.filetypes = {
	"c",
	"cpp",
	"lua",
	"rust",
	"python",
	"vim",
	"help",
	"query",
	"glsl",
	"hlsl",
	"markdown",
	"json",
	"sh",
	"bash",
}

function M.install_async()
	-- Headless verification must never download or compile parsers.
	if #vim.api.nvim_list_uis() == 0 then
		return
	end

	if vim.fn.executable("tree-sitter") == 0 then
		vim.schedule(function()
			vim.notify(
				"tree-sitter CLI not found; parsers cannot be installed.\n"
					.. "Install with: npm install -g tree-sitter-cli",
				vim.log.levels.WARN
			)
		end)
		return
	end

	local config = require("nvim-treesitter.config")
	local installed = config.get_installed("parsers")
	local missing = vim.tbl_filter(function(language)
		return not vim.list_contains(installed, language)
	end, M.languages)

	if #missing == 0 then
		return
	end

	vim.schedule(function()
		require("nvim-treesitter").install(missing, { summary = true })
	end)
end

function M.attach_autocmd()
	local group = vim.api.nvim_create_augroup("sal_treesitter", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = M.filetypes,
		callback = function(args)
			local language = vim.treesitter.language.get_lang(args.match)
			if not language or not pcall(vim.treesitter.language.add, language) then
				return
			end

			if not pcall(vim.treesitter.start, args.buf, language) then
				return
			end
			vim.wo[0][0].foldmethod = "expr"
			vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
		end,
	})
end

function M.setup()
	local ok, treesitter = pcall(require, "nvim-treesitter")
	if not ok then
		return
	end

	treesitter.setup({
		install_dir = vim.fn.stdpath("data") .. "/site",
	})

	M.install_async()
	M.attach_autocmd()
end

return M
