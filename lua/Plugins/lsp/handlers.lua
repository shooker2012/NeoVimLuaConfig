local M = {}

M.setup = function()
	-- Keep rounded borders as the preferred UI style. Border alignment depends
	-- on the terminal host's glyph measurement; verification uses the user's
	-- normal Windows Terminal profile instead of a separately spawned conhost.
	vim.o.winborder = "rounded"

	-- local signs = {
	--	 { name = "DiagnosticSignError", text = "" },
	--	 { name = "DiagnosticSignWarn", text = "" },
	--	 { name = "DiagnosticSignHint", text = "" },
	--	 { name = "DiagnosticSignInfo", text = "" },
	-- }

	-- for _, sign in ipairs(signs) do
	--	 vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
	-- end

	local config = {
		-- disable virtual text
		virtual_text = false,
		update_in_insert = false,
		underline = {
			severity = { min = _G.sal_diagnostic_severity },
		},
		severity_sort = true,
		float = {
			focusable = false,
			style = "minimal",
			source = true,
			header = "",
			prefix = "",
		},
		signs = {
			severity = { min = vim.diagnostic.severity.ERROR, }
		},
	}

	vim.diagnostic.config(config)

	-- Config on_attach and capabilities.
	local opts = {
		on_attach = M.on_attach,
		capabilities = M.capabilities,
	}
	vim.lsp.config("*", opts)
end

local function lsp_highlight_document(client, bufnr)
	-- Set autocommands conditional on server_capabilities
	if client.server_capabilities.documentHighlightProvider then
		local group = vim.api.nvim_create_augroup("sal_lsp_document_highlight_" .. bufnr, { clear = true })
		vim.api.nvim_create_autocmd("CursorHold", {
			group = group,
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = group,
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	end
end

local function lsp_keymaps(bufnr)
	local opts = { noremap = true, silent = true }
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>i", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
	-- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
	-- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
end

M.on_attach = function(client, bufnr)
	if client.name == "ts_ls" then
		client.server_capabilities.documentFormattingProvider = false
	end
	lsp_keymaps(bufnr)
	lsp_highlight_document(client, bufnr)
end

M.capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
	textDocument = {
		completion = {
			dynamicRegistration = false,
			completionItem = {
				snippetSupport = true,
				commitCharactersSupport = true,
				deprecatedSupport = true,
				preselectSupport = true,
				tagSupport = { valueSet = { 1 } },
				insertReplaceSupport = true,
				resolveSupport = {
					properties = {
						"documentation",
						"additionalTextEdits",
						"insertTextFormat",
						"insertTextMode",
						"command",
					},
				},
				insertTextModeSupport = { valueSet = { 1, 2 } },
				labelDetailsSupport = true,
			},
			contextSupport = true,
			insertTextMode = 1,
			completionList = {
				itemDefaults = {
					"commitCharacters",
					"editRange",
					"insertTextFormat",
					"insertTextMode",
					"data",
				},
			},
		},
	},
})

return M
