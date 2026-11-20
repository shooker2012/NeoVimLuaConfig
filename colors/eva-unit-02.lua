vim.cmd.source(vim.fn.fnameescape(vim.env.VIMRUNTIME .. "/colors/eva-unit-02.vim"))

local links = {
	["@variable.member"] = "Special",
	["@property"] = "Special",
	["@function"] = "Function",
	["@function.method"] = "Function",
	["@function.call"] = "Function",
	["@constant.builtin"] = "Constant",
	["@variable.parameter"] = "Constant",
	["@lsp.type.property"] = "Special",
	["@lsp.type.member"] = "Special",
	["@lsp.type.variable"] = "Identifier",
	["@lsp.type.parameter"] = "Constant",
	["@lsp.type.method"] = "Function",
	["@lsp.type.label"] = "Label",
	["@lsp.type.typeAlias"] = "Type",
	["@lsp.type.concept"] = "Type",
}

for group, target in pairs(links) do
	vim.api.nvim_set_hl(0, group, { link = target })
end
