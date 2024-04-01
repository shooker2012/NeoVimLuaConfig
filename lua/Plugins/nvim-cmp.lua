local has_words_before = function()
	unpack = unpack or table.unpack
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local snip_status_ok, luasnip = pcall(require, "luasnip")

local cmp = require("cmp")

cmp.setup({

	-- ... Your other configuration ...

	mapping = {

		-- ... Your other mappings ...

		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
				-- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable() 
				-- that way you will only jump inside the snippet region
			elseif luasnip and luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			elseif has_words_before() then
				--local keycode = vim.api.nvim_replace_termcodes("<C-n>", true, false, true)
				--vim.api.nvim_feedkeys(keycode, "m", false)
				--vim.api.nvim_input("<C-n>")
				fallback()
			else
				fallback()
			end
		end, { "i", "s" }),

		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip and luasnip.jumpable(-1) then
				luasnip.jump(-1)
			elseif has_words_before() then
				vim.api.nvim_input("<C-p>")
			else
				fallback()
			end
		end, { "i", "s" }),

		-- Accept currently selected item. If none selected, `select` first item.
		-- Set `select` to `false` to only confirm explicitly selected items.
		["<CR>"] = cmp.mapping.confirm { select = true },

		-- Snip jump
		["<C-J>"] = cmp.mapping(function(fallback)
			if luasnip and luasnip.jumpable(1) then
				luasnip.jump(1)
			else
				fallback()
			end
		end, {"i", "s"}),
		["<C-K>"] = cmp.mapping(function(fallback)
			if luasnip and luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, {"i", "s"}),

		-- ... Your other mappings ...
	},

	sources = {
		{ name = 'luasnip' },
		{ name = 'nvim_lsp' },
		{ name = "nvim_lua" },
		{ name = 'path' },
		{ name = 'buffer' },
	},

	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, vim_item)
		  -- Kind icons
		  vim_item.kind = string.format("[%s]", string.sub(vim_item.kind, 1, 1))
		  -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
		  vim_item.menu = ({
			luasnip = "[Snippet]",
			nvim_lsp = "[LSP]",
			nvim_lua = "[NVIM_LUA]",
			buffer = "[Buffer]",
			path = "[Path]",
		  })[entry.source.name]
		  return vim_item
		end,
	},

	confirm_opts = {
		behavior = cmp.ConfirmBehavior.Replace,
		select = false,
	},
	window = {
		documentation = cmp.config.window.bordered()
	},
	experimental = {
		ghost_text = false,
		native_menu = false,
	},

	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end
	},
	-- ... Your other configuration ...
})