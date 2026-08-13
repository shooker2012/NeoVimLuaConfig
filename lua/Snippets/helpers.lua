local parse = require("luasnip.util.parser").parse_snippet

local M = {}

---Create a parsed snippet whose default value comes from Vim's yank register.
---@param trigger string
---@param body string
---@return table
function M.parse_with_yank_register(trigger, body)
	return parse({
		trig = trigger,
		resolveExpandParams = function()
			return {
				env_override = {
					VIM_YANK_REGISTER = vim.fn.getreg("0"),
				},
			}
		end,
	}, body)
end

return M
