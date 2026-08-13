local ls = require("luasnip")
local parse = require("luasnip.util.parser").parse_snippet
local events = require("luasnip.util.events")
local feedkeys = require("luasnip.util.feedkeys")
---@diagnostic disable-next-line: undefined-global
local helpers = ls_tracked_dopackage("Snippets.helpers")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local function enum_row_node(position)
	return i(position, "", {
		node_callbacks = {
			[events.enter] = function(node)
				if node._enum_row_inserted then
					return
				end

				node._enum_row_inserted = true
				node:set_text({ "", '\t"",' })
				local _, row_end = node.mark:pos_begin_end_raw()
				feedkeys.insert_at({ row_end[1], row_end[2] - 2 })
			end,
		},
	})
end

local function enum_snippet()
	local nodes = {
		t("local "),
		i(1),
		t(" = Enum.make"),
		t({ "", "{" }),
		t('\t"'),
		i(2),
		t('", "=", '),
		i(3, "0"),
		t(","),
	}

	for position = 4, 50 do
		nodes[#nodes + 1] = enum_row_node(position)
	end

	nodes[#nodes + 1] = t({ "", "}" })
	nodes[#nodes + 1] = i(0)
	return s("enum", nodes)
end

return {
	-- Blocks and control flow.
	parse("context", [[context "${1}" do
	${0:${TM_SELECTED_TEXT:# assertions}}
end]]),

	parse("fori=", [[for i = $1, $2 do
	${0:${TM_SELECTED_TEXT:--loop body }}
end]]),

	parse("forip", [[for ${1:i}, ${2:v} in ipairs($3) do
	${0:${TM_SELECTED_TEXT:--loop body }}
end]]),

	parse("forp", [[for ${1:k}, ${2:v} in pairs($3) do
	${0:${TM_SELECTED_TEXT:--loop body }}
end]]),

	parse("if", [[if $1 then
	${2:${TM_SELECTED_TEXT:--body }}
end$0]]),

	parse("func", [[function($1)
	$0
end]]),

	-- Text helpers.
	parse("watch", [["${1:${TM_SELECTED_TEXT}}: "..tostring($1)$0]]),
	parse("curtime", [[$CURRENT_YEAR $CURRENT_MONTH $CURRENT_DATE]]),
	parse("todo", [[-- [TODO] $0]]),

	parse("testcode", [=[-- [TEST_CODE]
	${0:${TM_SELECTED_TEXT}}
-- [TEST_CODE_END]]=]),

	helpers.parse_with_yank_register("samplecode", [=[-- [SampelCode]
--[[
	${1:${VIM_YANK_REGISTER}}
--]]
$0]=]),

	-- Project-independent structured helper.
	enum_snippet(),
}
