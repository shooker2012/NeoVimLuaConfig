# Treesitter Modernization Specification

## Purpose

规定 Treesitter parser、高亮、折叠、textobjects 与 matchup 集成的现代化行为。

## Requirements

### Requirement: R1 恢复 treesitter parser 安装能力
系统 SHALL 实现“恢复 treesitter parser 安装能力”。作为使用者，我希望 C/C++、Rust、Python 等语言的 parser 能被正确安装，以便获得基于语法树的编辑能力。

#### Scenario: R1.1 验收条件
- **WHEN** 用户执行 `:checkhealth nvim-treesitter`
- **THEN** 系统 SHALL 报告 tree-sitter CLI 已找到且版本满足最低要求

#### Scenario: R1.2 验收条件
- **WHEN** 用户执行 `:checkhealth nvim-treesitter`
- **THEN** 系统 SHALL 报告 parser 安装目录已在 runtimepath 中

#### Scenario: R1.3 验收条件
- **WHEN** 带 UI 的 Neovim 会话启动完成且存在缺失 parser
- **THEN** 配置 SHALL 通过 `require('nvim-treesitter').install({...})` 声明需要的 parser 列表

#### Scenario: R1.4 验收条件
- **WHEN** parser 安装完成
- **THEN** `require('nvim-treesitter.config').get_installed('parsers')` SHALL 至少包含 c、cpp、lua、rust、python、vim、vimdoc、glsl、hlsl、markdown、json、bash

#### Scenario: R1.5 验收条件
- **WHEN** tree-sitter CLI 缺失
- **THEN** 配置 SHALL NOT 在启动时抛出错误或阻塞启动

#### Scenario: R1.6 验收条件
- **WHEN** 安装为耗时操作
- **THEN** 配置 SHALL NOT 在启动路径上同步等待安装完成

#### Scenario: R1.7 验收条件
- **WHEN** `init.lua` 已为 glsl 与 hlsl 设置 filetype 规则
- **THEN** parser 列表 SHALL 与这些 filetype 保持对应

#### Scenario: R1.8 验收条件
- **WHEN** 用户打开 `.hlsl` 或 `.fx` 文件
- **THEN** filetype SHALL 为 `hlsl` 并直接对应 hlsl parser

#### Scenario: R1.9 headless 安装边界
- **WHEN** Neovim 运行于无 UI 的 headless 会话
- **THEN** 配置 SHALL NOT 下载或编译缺失 parser

#### Scenario: R1.10 shader 扩展名覆盖
- **WHEN** 用户打开 `.shader` 或 `.vsh` 文件
- **THEN** filetype SHALL 分别固定为 `hlsl` 与 `glsl`，即使这会覆盖 Neovim 对 Godot shader 与 V 语言的内置判断

### Requirement: R2 恢复 treesitter 语法高亮
系统 SHALL 实现“恢复 treesitter 语法高亮”。作为使用者，我希望打开 C++ 文件时获得基于语法树的高亮，而不是回落到 Vim 正则高亮。

#### Scenario: R2.1 验收条件
- **WHEN** 用户打开一个已安装 parser 的文件类型
- **THEN** 系统 SHALL 调用 `vim.treesitter.start()` 启动高亮

#### Scenario: R2.2 验收条件
- **WHEN** 用户打开 `.cpp` 文件
- **THEN** `vim.treesitter.highlighter.active[bufnr]` SHALL 不为 nil

#### Scenario: R2.3 验收条件
- **WHEN** 当前文件类型的 parser 未安装
- **THEN** 系统 SHALL 静默回落到内置 syntax 而不报错

#### Scenario: R2.4 验收条件
- **WHEN** treesitter 高亮已启动
- **THEN** 配置 SHALL NOT 同时启用 `additional_vim_regex_highlighting`

### Requirement: R3 修复折叠表达式
系统 SHALL 实现“修复折叠表达式”。作为使用者，我希望开启折叠时能按函数、类等语法节点折叠，而不是报错。

#### Scenario: R3.1 验收条件
- **WHEN** 用户在支持的文件类型中开启折叠
- **THEN** 系统 SHALL NOT 报告 `E117: Unknown function: nvim_treesitter#foldexpr`

#### Scenario: R3.2 验收条件
- **WHEN** 折叠生效
- **THEN** `foldexpr` SHALL 使用 `v:lua.vim.treesitter.foldexpr()`

#### Scenario: R3.3 验收条件
- **WHEN** 折叠表达式为窗口局部选项
- **THEN** 配置 SHALL 使用窗口局部方式设置而非全局 `vim.o`

#### Scenario: R3.4 验收条件
- **WHEN** 用户打开文件
- **THEN** `foldenable` 的默认关闭行为 SHALL 保持不变

### Requirement: R4 清理 treesitter 死配置并恢复 matchup 集成
系统 SHALL 实现“清理 treesitter 死配置并恢复 matchup 集成”。作为维护者，我希望配置文件中不留下不被读取的字段，避免以后误判为生效。

#### Scenario: R4.1 验收条件
- **WHEN** 审阅 treesitter 配置
- **THEN** 配置 SHALL NOT 包含 `main` 分支不识别的字段（`ensure_installed`、`highlight`、`auto_install`、`ignore_install`、`sync_install`、`matchup`、`indent`）

#### Scenario: R4.2 验收条件
- **WHEN** 审阅 textobjects 配置
- **THEN** `setup()` 调用 SHALL NOT 包含不被识别的 `keymaps` 字段

#### Scenario: R4.3 验收条件
- **WHEN** textobjects 按键映射生效
- **THEN** `as` 映射的 query SHALL 在配置中保持唯一且一致的定义

#### Scenario: R4.4 验收条件
- **WHEN** vim-matchup 加载
- **THEN** 其 treesitter 集成 SHALL 通过 vim-matchup 自身的选项配置，而非 treesitter 的 setup

#### Scenario: R4.5 验收条件
- **WHEN** 审阅插件声明
- **THEN** `vim-matchup` SHALL 只声明一次
