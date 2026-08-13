local ls = require("luasnip")
local parse = require("luasnip.util.parser").parse_snippet
---@diagnostic disable-next-line: undefined-global
local helpers = ls_tracked_dopackage("Snippets.helpers")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function previous_text_index()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	if row <= 1 then
		return nil
	end

	local previous = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1] or ""
	return tonumber(previous:match("^%s*text%[(%d+)%]"))
end

local function next_text_prefix()
	local index = previous_text_index()
	return string.format('text[%d] = "', (index or 0) + 1)
end

return {
	-- Class and module templates.
	parse("newclass", [[local Lplus = require "Lplus"
local ${1:${TM_FILENAME_BASE}} = Lplus.Class("$1")
local def = $1.define

$1.Commit()
return $1]]),

	parse("exclass", [[local Lplus = require "Lplus"
local ${1:${TM_FILENAME_BASE}} = Lplus.Extend(${2:AzureActorBase}, "$1")
local def = $1.define

$1.Commit()
return $1]]),

	parse("newpanel", [[local Lplus = require "Lplus"
local ECPanelBase = require "Core.GUI.ECPanelBase"

local ${1:${TM_FILENAME_BASE}} = Lplus.Extend(ECPanelBase, "$1")

local def = $1.define

local l_instance = nil
def.static("=>", $1).Instance = function()
	if not l_instance then
		l_instance = $1()
	end

	return l_instance
end

def.override("=>", "string").GetAssetPath = function(self)
	return _G.RESPATH.$2
end

def.override("=>", "number").GetGUILevel = function(self)
	return _G.GUILevel.${3:ABSOLUTE}
end

def.override("=>", "number").GetGUILayer = function(self)
	return _G.GUILayer.$4
end

def.override("=>", TNumber).GetGUIDepth = function(self)
	return _G.GUIDepth.$5
end

def.override().OnCreate = function(self)
end

def.override().OnDestroy = function(self)
end

$1.Commit()
return $1]]),

	parse("newmodule", [[local Lplus = require "Lplus"
local ECModuleBase = require "Modules.ECModuleBase"

-- require

if not IsRunningDedicatedServer() then
	-- Client require.
end

---@class $1:ECModuleBase
---@field public Commit fun():$1 @notnull
---@field public StartupModule fun(self:$1)
---@field public ShutdownModule fun(self:$1)
local ${1:${TM_FILENAME_BASE}} = Lplus.Extend(ECModuleBase, "$1")

local def = $1.define

-------------------------------------------------------------------------------
---@param self $1
---@return void
def.override().StartupModule = function (self)
	--初始化内部逻辑以及注册监听 此时还未执行GameInit
end

---@param self $1
---@return void
def.override().ShutdownModule = function (self)
	--预留 尚未使用
end

-------------------------------------------------------------------------------
$1.Commit()
return $1]]),

	parse("newview", [[local Lplus = require "Lplus"
local ECViewBase = require "GUI.View.ECViewBase"

local ${1:${TM_FILENAME_BASE}} = Lplus.Extend(ECViewBase, "$1")

local def = $1.define

def.override().OnInit = function(self)
end

def.override().OnDestroy = function(self)
end

$1.Commit()
return $1]]),

	parse("newevent", [[local ${1:${TM_FILENAME_BASE}} = Lplus.Class("$1")
do
	local def = $1.define$2
end
$1.Commit()
$0]]),

	-- Lplus definitions and functions.
	parse("defm", [[def.method($1).$2 = function(self$3)
	$0
end]]),
	parse("defv", [[def.virtual($1).$2 = function(self$3)
	$0
end]]),
	parse("defo", [[def.override($1).$2 = function(self$3)
	$0
end]]),
	parse("defs", [[def.static($1).$2 = function($3)
	$0
end]]),
	parse("deff", [[def.field("$1").$2 = $0]]),
	parse("debug", [[warn("~~~~~~~~~~$1",$2 ${0:debug.traceback()})]]),

	helpers.parse_with_yank_register(
		"fd",
		[[local ${1:${VIM_YANK_REGISTER}} = Lplus.ForwardDeclare("$0$1")]]
	),

	parse("localfunc", [[local $1 = function($2)
	$3
end
Lplus.handleLocalFunc()
$0]]),

	-- Context-sensitive text assignment.
	s({
		trig = "t",
		name = "next indexed text assignment",
		condition = function()
			return previous_text_index() ~= nil
		end,
	}, {
		f(next_text_prefix),
		i(1),
		t('"'),
		i(0),
	}),

	-- Widget bindings and panel helpers.
	helpers.parse_with_yank_register("bindbutton", [[_G.ECGUITools.RegisterButtonClickEvent(${1:${VIM_YANK_REGISTER}}, function()
	$2
end)
$0]]),

	helpers.parse_with_yank_register("bindtext", [[${1:${VIM_YANK_REGISTER}}.OnTextChanged:UnBindAll()
$1.OnTextChanged:Bind(function(newText)
	$2
end)
$0]]),

	helpers.parse_with_yank_register(
		"setswitcher",
		[[${1:${VIM_YANK_REGISTER}}:SetActiveWidgetIndex(${2:condition and 0 or 1})]]
	),

	helpers.parse_with_yank_register("bindradiobox", [[${1:${VIM_YANK_REGISTER}}.OnCheckStateChanged:UnBindAll()
$1.OnCheckStateChanged:Add(function(isChecked)
	${2:--目前版本，只会在isChecked == true的时候收到消息。}
end)
$0]]),

	parse("bindscrolllist", [[local itemDatas = {}
${1:scrollList} = ECScrollList(self:GetWidget().$2)

$1:SetUpdateFunction(function(itemWidget, index)
	$3
end)
$1:SetCount(#itemDatas)
$0]]),

	parse("fix_panel", [[def.override("=>", "string").GetAssetPath = function(self)
	return _G.RESPATH.$1
end

def.override("=>", "number").GetGUILevel = function(self)
	return _G.GUILevel.${2:ABSOLUTE}
end

def.override("=>", "number").GetGUILayer = function(self)
	return _G.GUILayer.$3
end

def.override("=>", TNumber).GetGUIDepth = function(self)
	return _G.GUIDepth.$4
end]]),

	parse("seticon", [[_G.ECGUITools.SetImageById(${1:widget}, ${2:imgID})]]),
}
