param(
    [ValidateSet('treesitter', 'tooling', 'lazy-loading', 'all')]
    [string]$Suite = 'all',

    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'manual-tests')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)

function Reset-SuiteDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$SuiteName
    )

    $suitePath = [System.IO.Path]::GetFullPath((Join-Path $OutputDirectory $SuiteName))
    $outputPrefix = $OutputDirectory.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $suitePath.StartsWith($outputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to reset suite outside output directory: $suitePath"
    }

    if (Test-Path -LiteralPath $suitePath) {
        # Keep the suite root itself: on Windows an open Neovim may use it as
        # the current directory, which prevents deleting the directory even
        # though its generated contents can still be replaced safely.
        Get-ChildItem -LiteralPath $suitePath -Force | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
    }
}

function Write-FixtureFile {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $path = Join-Path $OutputDirectory $RelativePath
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [System.IO.File]::WriteAllText($path, ($Content.TrimStart("`r", "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
}

function New-TreesitterSuite {
    Write-FixtureFile 'treesitter/sample.cpp' @'
#include <vector>

class Counter {
public:
    int sum(const std::vector<int>& values) const {
        int result = 0;
        for (int value : values) {
            result += value;
        }
        return result;
    }
};
'@
    Write-FixtureFile 'treesitter/sample.lua' @'
local function map(values, transform)
  local result = {}
  for index, value in ipairs(values) do
    result[index] = transform(value)
  end
  return result
end

return map({ 1, 2, 3 }, function(value)
  return value * 2
end)
'@
    Write-FixtureFile 'treesitter/sample-context.lua' @'
local function build_report(groups)
  local report = {}

  for group_name, values in pairs(groups) do
    local group = {
      name = group_name,
      rows = {},
    }

    for index, value in ipairs(values) do
      local row = {
        index = index,
        original = value,
        normalized = value * 2,
      }

      -- Padding keeps the active nested scopes above the visible window after
      -- moving to the marker near the bottom of this block.
      row.step01 = row.normalized + 1
      row.step02 = row.step01 + 1
      row.step03 = row.step02 + 1
      row.step04 = row.step03 + 1
      row.step05 = row.step04 + 1
      row.step06 = row.step05 + 1
      row.step07 = row.step06 + 1
      row.step08 = row.step07 + 1
      row.step09 = row.step08 + 1
      row.step10 = row.step09 + 1
      row.step11 = row.step10 + 1
      row.step12 = row.step11 + 1
      row.step13 = row.step12 + 1
      row.step14 = row.step13 + 1
      row.step15 = row.step14 + 1
      row.step16 = row.step15 + 1
      row.step17 = row.step16 + 1
      row.step18 = row.step17 + 1
      row.step19 = row.step18 + 1
      row.step20 = row.step19 + 1
      row.step21 = row.step20 + 1
      row.step22 = row.step21 + 1
      row.step23 = row.step22 + 1
      row.step24 = row.step23 + 1
      row.step25 = row.step24 + 1
      row.step26 = row.step25 + 1
      row.step27 = row.step26 + 1
      row.step28 = row.step27 + 1
      row.step29 = row.step28 + 1
      row.step30 = row.step29 + 1

      local context_marker = row.step30
      group.rows[#group.rows + 1] = context_marker
    end

    report[#report + 1] = group
  end

  return report
end

return build_report({ alpha = { 1, 2, 3 } })
'@
    Write-FixtureFile 'treesitter/sample-matchup.lua' @'
local function matchup_demo(values)
  local total = 0
  for _, value in ipairs(values) do
    total = total + value
  end
  return total
end -- matchup_close_marker

return matchup_demo({ 1, 2, 3 })
'@
    Write-FixtureFile 'treesitter/sample.hlsl' @'
float4 main(float4 position : POSITION) : SV_POSITION {
    return position;
}
'@
    Write-FixtureFile 'treesitter/sample.fx' @'
float4 tint(float4 color : COLOR0) : COLOR0 {
    return color * float4(1.0, 0.8, 0.6, 1.0);
}
'@
    Write-FixtureFile 'treesitter/sample.vert' @'
#version 450
layout(location = 0) in vec3 position;
void main() {
    gl_Position = vec4(position, 1.0);
}
'@
    Write-FixtureFile 'treesitter/sample.vsh' @'
#version 450
void main() {
    gl_Position = vec4(0.0);
}
'@
    Write-FixtureFile 'treesitter/sample.shader' @'
float4 fragment() : SV_Target {
    return float4(0.2, 0.4, 0.8, 1.0);
}
'@
    Write-FixtureFile 'treesitter/sample.md' @'
# Treesitter fixture

Use **bold text**, a [link](https://example.com), and a fenced block:

```lua
print("treesitter")
```
'@
    Write-FixtureFile 'treesitter/TESTING.md' @'
# Treesitter 与 filetype 人工验证

先正常启动一次带界面的 `nvim`，等待 parser 安装摘要完成；然后在本目录执行：

`nvim sample.cpp sample.lua sample-context.lua sample-matchup.lua sample.hlsl sample.fx sample.vert sample.vsh sample.shader sample.md`

| 结果 | 操作 | 预期现象 |
| --- | --- | --- |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 执行 `:checkhealth nvim-treesitter` | tree-sitter CLI 可用，安装目录位于 runtimepath，目标 parser 已安装 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 对每个 buffer 执行 `:set filetype?` | C++/Lua/HLSL/FX/GLSL/VSH/SHADER/Markdown 分别识别为 `cpp`、`lua`、`hlsl`、`hlsl`、`glsl`、`glsl`、`hlsl`、`markdown` |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 观察各文件并执行 `:InspectTree` | 语法高亮存在，语法树可打开且无错误 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在 C++/Lua 中执行 `zM`、`zR` | treesitter 折叠可用，无 `E117` |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 打开 `sample-matchup.lua`，执行 `/matchup_close_marker`、`0`，观察后按 `%` | 光标位于外层 `end` 时，它与第 1 行的 `function` 获得配对高亮；按 `%` 后光标直接跳到第 1 行的 `function`（Lua 关键字配对来自 vim-matchup 的 Treesitter 查询） |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 打开 `sample-context.lua`，执行 `/context_marker`，再执行 `zt` | 光标仍位于嵌套函数和两层循环内；这些已滚出视野的作用域头显示在窗口顶部的 treesitter-context 浮窗中 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在函数中使用 visual/operator 模式的 `af`、`if`、`ac`、`ic`、`as` | textobjects 选择正确且每个映射只执行一次 |

备注/失败信息：
'@
}

function New-ToolingSuite {
    Write-FixtureFile 'tooling/format.cpp' @'
#include <iostream>
int main(){std::cout<<"format"<<std::endl;return 0;}
'@
    Write-FixtureFile 'tooling/format.lua' @'
local values={1,2,3}
for _,value in ipairs(values) do print(value) end
'@
    Write-FixtureFile 'tooling/format.py' @'
def greet(name):
 return f"hello, {name}"
'@
    Write-FixtureFile 'tooling/rust-project/Cargo.toml' @'
[package]
name = "nvim-modernization-fixture"
version = "0.1.0"
edition = "2021"
'@
    Write-FixtureFile 'tooling/rust-project/src/main.rs' @'
fn main(){println!("format");}
'@
    Write-FixtureFile 'tooling/TESTING.md' @'
# API 迁移与格式化人工验证

在本目录执行 `nvim format.cpp format.lua format.py rust-project/src/main.rs`。

| 结果 | 操作 | 预期现象 |
| --- | --- | --- |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在 C++、Lua、Python buffer 执行 `:Format` | 可用 formatter 存在时完成格式化；缺失时显示可读提示且无 Lua 堆栈 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | visual 选择数行后执行 `:'<,'>Format` | 仅选择范围被格式化 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在 Rust 文件执行 `:Format` | 通过 rust_analyzer 的 LSP 格式化 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 分别打开 Lua、Python、Rust 文件并执行 `:lua =vim.lsp.get_clients()` | 分别可见 lua_ls、pyright、rust_analyzer |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 使用 `[d`、`]d`、`K`、`<Leader>e` | 诊断跳转与 LSP 浮窗正常，边框为 rounded |

备注/失败信息：
'@
}

function New-LazyLoadingSuite {
    Write-FixtureFile 'lazy-loading/sample.lua' @'
---@param name string
---@return string
local function greet(name)
  return "hello, " .. name
end

local greeting = greet("Neovim")
local diagnostic_probe = missing_name + 1

return {
  greeting = greeting,
  diagnostic_probe = diagnostic_probe,
}
'@
    Write-FixtureFile 'lazy-loading/format.lua' @'
local values={1,2,3}
for _,value in ipairs(values) do print(value) end
'@
    Write-FixtureFile 'lazy-loading/words.txt' @'
alpha beta gamma
alpha delta gamma
'@
    Write-FixtureFile 'lazy-loading/TESTING.md' @'
# 懒加载与最终体验人工验证

请先打开平时使用的 Windows Terminal profile，进入本目录后执行：

`nvim sample.lua format.lua words.txt`

只检查下面能在 Neovim 中直接看到的行为；无需查看插件内部加载状态、LSP client 列表或自动化脚本输出。不要通过资源管理器、`Start-Process nvim` 或其他会另起传统 conhost 的方式启动本次视觉验收。

| 结果 | 操作 | 预期现象 |
| --- | --- | --- |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在 `sample.lua` 的 `greet` 上按 `K`；把光标放到 `greet("Neovim")` 的参数内按 `<C-k>` | hover 与 signature help 都正常出现，rounded 边框无错位 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 等 `missing_name` 出现诊断后，把光标放在该行按 `<Leader>e`，并用 `[d` / `]d` 跳转 | diagnostic float 与跳转正常，浮窗为 rounded 边框 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | normal 模式分别按 `<C-p>`、`<C-f>`、`<C-b>`；把光标放在 `words.txt` 的 `alpha` 上按 `<F3>` | Telescope 首次按键即可打开并执行对应查找，窗口外观正常 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | visual 选中 `alpha`，分别测试 `<C-p>`、`<C-f>`、`<C-b>`、`<F3>` | visual 模式按键均可触发；`<F3>` 搜索选中文本而不是光标单词 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在 `sample.lua` normal 模式按 `<F4>`、关闭后按 `<S-F4>` | aerial 两个入口首次执行即可用，分别保持原有选择后关闭/保留行为 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在 `words.txt` 中分别从 normal、visual、operator-pending（例如先按 `d`）模式按 `s` | 三种模式都出现 Hop 双字符提示且可完成跳转，提示外观正常 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 新会话中不先进入 insert，直接输入 `:`；随后在 `words.txt` 输入 `/alp` 和 `?gam` | `:`、`/`、`?` 都直接出现 nvim-cmp 补全菜单，回车仍能正常执行命令/搜索 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在任一文件按 `<F9>` 打开 Neo-tree，按 `a` 查看新建项输入框后按 `<Esc>` 取消 | Neo-tree 可用，输入浮窗边框正常且没有错位，不会创建文件 |
| [ ] 通过 [ ] 失败 [ ] 未验证 | 在 `format.lua` 执行 `:Format`，再 visual 选中数行执行 `:'<,'>Format` | formatter 可用时完成格式化；缺失时显示可读提示且无 Lua 堆栈，范围命令首次执行可用 |
备注/失败信息：
'@
}

[void](New-Item -ItemType Directory -Path $OutputDirectory -Force)

switch ($Suite) {
    'treesitter' {
        Reset-SuiteDirectory 'treesitter'
        New-TreesitterSuite
    }
    'tooling' {
        Reset-SuiteDirectory 'tooling'
        New-ToolingSuite
    }
    'lazy-loading' {
        Reset-SuiteDirectory 'lazy-loading'
        New-LazyLoadingSuite
    }
    'all' {
        Reset-SuiteDirectory 'treesitter'
        Reset-SuiteDirectory 'tooling'
        Reset-SuiteDirectory 'lazy-loading'
        New-TreesitterSuite
        New-ToolingSuite
        New-LazyLoadingSuite
    }
}

Write-Host "Generated '$Suite' manual-test suite in $OutputDirectory"
