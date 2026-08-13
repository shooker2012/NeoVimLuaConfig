local M = {}

M.formatters_by_ft = {
	c = { "clang-format" },
	cpp = { "clang-format" },
	lua = { "stylua" },
	python = { "ruff_format", "black", stop_after_first = true },
}

function M.setup()
	require("conform").setup({
		formatters_by_ft = M.formatters_by_ft,
		default_format_opts = { lsp_format = "fallback" },
		format_on_save = false,
		notify_on_error = true,
		notify_no_formatters = true,
	})
end

function M.register_command()
	vim.api.nvim_create_user_command("Format", function(args)
		local range
		if args.count ~= -1 then
			range = {
				start = { args.line1, 0 },
				["end"] = { args.line2, math.huge },
			}
		end

		require("conform").format({
			async = true,
			lsp_format = "fallback",
			range = range,
		})
	end, { range = true, desc = "Format buffer or range" })
end

return M
