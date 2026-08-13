local ls = require("luasnip")
local parse = require("luasnip.util.parser").parse_snippet

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function at_line_start(trigger)
	return function(line_to_cursor)
		return line_to_cursor:match("^%s*" .. trigger) ~= nil
	end
end

local function log_values(_, snip)
	local values = vim.split(snip.captures[1] or "", ",", { plain = true, trimempty = true })
	local params = {}

	for _, value in ipairs(values) do
		value = vim.trim(value)
		if value ~= "" then
			params[#params + 1] = string.format('"%s: "..tostring(%s)', value, value)
		end
	end

	return table.concat(params, ", ")
end

local function log_nil_checks(_, snip)
	local expression = vim.trim(snip.captures[1] or "")
	local prefixes = {}
	local start = 1

	while true do
		local separator = expression:find("[%.:]", start)
		if not separator then
			break
		end
		prefixes[#prefixes + 1] = expression:sub(1, separator - 1)
		start = separator + 1
	end

	if expression ~= "" then
		prefixes[#prefixes + 1] = expression
	end

	local lines = {}
	for _, prefix in ipairs(prefixes) do
		lines[#lines + 1] = string.format('warn("~~~~~~~~~~log check nil: %s", %s)', prefix, prefix)
	end

	return lines
end

return {
	parse("log", [[warn("~~~~~~~~~~log $1"$2)]]),

	s({
		trig = "logv (.*);",
		name = "log values",
		regTrig = true,
		wordTrig = false,
		condition = at_line_start("logv "),
	}, {
		t('warn( "~~~~~~~~~~log '),
		i(1),
		t(':", '),
		f(log_values),
		i(2),
		t(" )"),
		i(0),
	}),

	s({
		trig = "lognil (.*);",
		name = "log nil prefixes",
		regTrig = true,
		wordTrig = false,
		condition = at_line_start("lognil "),
	}, {
		t("-- [TEST_CODE]"),
		t({ "", "" }),
		f(log_nil_checks),
		i(0),
		t({ "", "-- [TEST_CODE_END]" }),
	}),
}
