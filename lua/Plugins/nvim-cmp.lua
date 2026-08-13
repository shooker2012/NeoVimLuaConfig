local unpack = unpack or table.unpack

local has_words_before = function()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({

	-- ... Your other configuration ...

	mapping = {

		-- ... Your other mappings ...
		["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),

		["<Tab>"] = cmp.mapping(function(fallback)
			if luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			elseif cmp.visible() then
				cmp.select_next_item({behavior = cmp.SelectBehavior.Insert})
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
			elseif has_words_before() then
				vim.api.nvim_input("<C-p>")
			else
				fallback()
			end
		end, { "i", "s" }),

		-- Accept currently selected item. If none selected, `select` first item.
		-- Set `select` to `false` to only confirm explicitly selected items.
		["<CR>"] = cmp.mapping.confirm { select = false },

		-- Snip jump
		["<C-J>"] = cmp.mapping(function(fallback)
			if luasnip.locally_jumpable(1) then
				luasnip.jump(1)
			else
				fallback()
			end
		end, {"i", "s"}),
		["<C-K>"] = cmp.mapping(function(fallback)
			if luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, {"i", "s"}),

		["<C-E>"] = cmp.abort,

		-- ... Your other mappings ...
	},

	sources = {
		{ name = 'luasnip' },
		-- { name = 'nvim_lsp', max_item_count = 5 },
		{ name = 'nvim_lsp' },
		{ name = "nvim_lua" },
		{ name = 'path', group_index = 2 },
		{ name = 'buffer', group_index = 2 },
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

local cmdline_mapping = cmp.mapping.preset.cmdline()

cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmdline_mapping,
	sources = {
		{ name = "buffer" },
	},
	experimental = {
		native_menu = false,
	},
})

cmp.setup.cmdline(":", {
	mapping = cmdline_mapping,
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
	experimental = {
		native_menu = false,
	},
})
