> **只读历史文档**：本任务已迁移到 `openspec/changes/nvim-config-modernization/`，后者是当前唯一实施与验收依据。

# Requirements Document

## Introduction

本 spec 覆盖对当前 Neovim 配置（`%LOCALAPPDATA%\nvim`）的一次现代化改造。

审查发现的核心问题：`nvim-treesitter` 已锁定在 `main` 分支（重写版），但配置仍使用 `master` 分支的旧 API，导致 treesitter 相关能力（parser 安装、语法高亮、折叠、matchup 集成）整体失效。除此之外还存在一批已废弃或已移除的 API 调用、一个从未被引用的归档插件、全局变量泄漏，以及启动性能上的优化空间。

### 环境基线（已实测确认）

| 项 | 值 |
| --- | --- |
| Neovim | v0.11.6 (tree-sitter ABI 15) |
| nvim-treesitter | `main` 分支，commit `2b50ab5` |
| 已安装 parser | 无（`nvim-data/site/parser` 为空） |
| `site/` 是否在 runtimepath | 否 |
| tree-sitter CLI | 未安装 |
| zig | 0.12.0-dev，在 PATH（main 分支不再使用） |
| git / node / npm / tar / curl | 均可用 |
| clang-format / stylua / black / ruff | 均未安装 |

### 关键前提

`main` 分支上游尚未宣布稳定（README 明示「等被认为稳定后才会支持最新 release」，缩进功能仍标记 experimental）。选择迁移到 `main` 是经过权衡的决定：`master` 已冻结且只做向后兼容，`main` 是上游进 Neovim 的方向，且 lock 文件已在 `main`。代价是需接受后续可能的 API 变动。

### 范围外

- 不改变现有按键映射的语义（除被迫迁移的废弃 API）
- 不改动 `lsp/lua_ls.lua` 的原生 `lsp/` 目录布局（已验证生效）
- 不引入新的补全引擎或 colorscheme
- 不引入 lint 插件（`nvim-lint`）；诊断继续由各语言服务器提供

---

## Requirements

### Requirement 1: 恢复 treesitter parser 安装能力

**User Story:** 作为使用者，我希望 C/C++、Rust、Python 等语言的 parser 能被正确安装，以便获得基于语法树的编辑能力。

#### Acceptance Criteria

1. WHEN 用户执行 `:checkhealth nvim-treesitter` THEN 系统 SHALL 报告 tree-sitter CLI 已找到且版本满足最低要求
2. WHEN 用户执行 `:checkhealth nvim-treesitter` THEN 系统 SHALL 报告 parser 安装目录已在 runtimepath 中
3. WHEN Neovim 启动完成 THEN 配置 SHALL 通过 `require('nvim-treesitter').install({...})` 声明需要的 parser 列表
4. WHEN parser 安装完成 THEN `require('nvim-treesitter.config').get_installed('parsers')` SHALL 至少包含 c、cpp、lua、rust、python、vim、vimdoc、glsl、hlsl、markdown、json、bash
5. IF tree-sitter CLI 缺失 THEN 配置 SHALL NOT 在启动时抛出错误或阻塞启动
6. WHERE 安装为耗时操作 THE 配置 SHALL NOT 在启动路径上同步等待安装完成
7. WHERE `init.lua` 已为 glsl 与 hlsl 设置 filetype 规则 THE parser 列表 SHALL 与这些 filetype 保持对应
8. WHEN 用户打开 `.hlsl` 或 `.fx` 文件 THEN 现有的 `setf fx` filetype 规则 SHALL 与 hlsl parser 的注册名称正确对应

### Requirement 2: 恢复 treesitter 语法高亮

**User Story:** 作为使用者，我希望打开 C++ 文件时获得基于语法树的高亮，而不是回落到 Vim 正则高亮。

#### Acceptance Criteria

1. WHEN 用户打开一个已安装 parser 的文件类型 THEN 系统 SHALL 调用 `vim.treesitter.start()` 启动高亮
2. WHEN 用户打开 `.cpp` 文件 THEN `vim.treesitter.highlighter.active[bufnr]` SHALL 不为 nil
3. IF 当前文件类型的 parser 未安装 THEN 系统 SHALL 静默回落到内置 syntax 而不报错
4. WHEN treesitter 高亮已启动 THEN 配置 SHALL NOT 同时启用 `additional_vim_regex_highlighting`

### Requirement 3: 修复折叠表达式

**User Story:** 作为使用者，我希望开启折叠时能按函数、类等语法节点折叠，而不是报错。

#### Acceptance Criteria

1. WHEN 用户在支持的文件类型中开启折叠 THEN 系统 SHALL NOT 报告 `E117: Unknown function: nvim_treesitter#foldexpr`
2. WHEN 折叠生效 THEN `foldexpr` SHALL 使用 `v:lua.vim.treesitter.foldexpr()`
3. WHERE 折叠表达式为窗口局部选项 THE 配置 SHALL 使用窗口局部方式设置而非全局 `vim.o`
4. WHEN 用户打开文件 THEN `foldenable` 的默认关闭行为 SHALL 保持不变

### Requirement 4: 清理 treesitter 死配置并恢复 matchup 集成

**User Story:** 作为维护者，我希望配置文件中不留下不被读取的字段，避免以后误判为生效。

#### Acceptance Criteria

1. WHEN 审阅 treesitter 配置 THEN 配置 SHALL NOT 包含 `main` 分支不识别的字段（`ensure_installed`、`highlight`、`auto_install`、`ignore_install`、`sync_install`、`matchup`、`indent`）
2. WHEN 审阅 textobjects 配置 THEN `setup()` 调用 SHALL NOT 包含不被识别的 `keymaps` 字段
3. WHEN textobjects 按键映射生效 THEN `as` 映射的 query SHALL 在配置中保持唯一且一致的定义
4. WHEN vim-matchup 加载 THEN 其 treesitter 集成 SHALL 通过 vim-matchup 自身的选项配置，而非 treesitter 的 setup
5. WHEN 审阅插件声明 THEN `vim-matchup` SHALL 只声明一次

### Requirement 5: 替换已移除与已废弃的 API

**User Story:** 作为使用者，我希望所有按键和命令都能正常工作，并且配置在未来的 Neovim 版本中不会失效。

#### Acceptance Criteria

1. WHEN 用户执行 `:Format` 命令 THEN 系统 SHALL NOT 调用已移除的 `vim.lsp.buf.formatting()`
2. WHEN LSP 客户端挂载 THEN document highlight 的能力判断 SHALL 使用正确的 `documentHighlightProvider` 字段
3. WHEN LSP 客户端支持 document highlight THEN 对应的 autocmd SHALL 被成功创建
4. WHEN 用户使用 `[d` / `]d` 跳转诊断 THEN 系统 SHALL 使用 `vim.diagnostic.jump()` 而非已废弃的 `goto_prev` / `goto_next`
5. WHEN 诊断跳转发生 THEN 严重程度过滤行为 SHALL 与原有 `_G.sal_diagnostic_severity` 语义保持一致
6. WHEN 配置浮窗边框 THEN 系统 SHALL 使用 `vim.o.winborder` 而非已废弃的 `vim.lsp.with()` 覆盖 handler
7. WHEN 创建 autocmd THEN 配置 SHALL 使用 `nvim_create_autocmd` 而非已废弃的 `nvim_exec()`
8. WHEN 检测 lazy.nvim 安装路径 THEN 配置 SHALL 使用 `vim.uv` 而非已废弃的 `vim.loop`
9. WHEN 配置诊断浮窗的 source 显示 THEN 取值 SHALL 为合法的 `boolean` 或 `'if_many'`
10. WHEN 判断 TypeScript 语言服务器 THEN 名称比较 SHALL 使用当前名称 `ts_ls`

### Requirement 6: 引入 conform.nvim 提供代码格式化

**User Story:** 作为使用者，我希望能对 C/C++ 与 Lua 代码执行格式化，并且格式化入口统一，不依赖已归档的插件。

#### Acceptance Criteria

1. WHEN 用户执行 `:Format` 命令 THEN 系统 SHALL 通过 conform.nvim 执行格式化
2. WHERE 文件类型为 c 或 cpp THE conform SHALL 配置 `clang-format` 作为格式化器
3. WHERE 文件类型为 lua THE conform SHALL 配置 `stylua` 作为格式化器
4. WHERE 文件类型为 python THE conform SHALL 配置可用的格式化器
5. WHERE 文件类型为 rust THE 格式化 SHALL 交由 rust_analyzer 的 LSP 格式化能力处理
6. IF 某文件类型没有配置外部格式化器 THEN conform SHALL 回落到 LSP 格式化
7. IF 配置的格式化器可执行文件缺失 THEN 系统 SHALL 给出可读的提示而非静默失败或抛出堆栈
8. WHEN 用户执行格式化 THEN 格式化 SHALL NOT 自动在保存时触发（保持显式调用）
9. WHEN conform 被引入 THEN 它 SHALL 采用懒加载，不增加启动时的模块加载
10. WHEN 格式化依赖的外部工具未安装 THEN 该依赖 SHALL 被记录到 README 的安装说明中

### Requirement 7: 移除归档的死依赖

**User Story:** 作为使用者，我不希望为从未使用的插件付出加载开销。

#### Acceptance Criteria

1. WHEN 审阅插件列表 THEN `jose-elias-alvarez/null-ls.nvim` SHALL 被移除
2. WHEN null-ls 被移除 THEN 配置中 SHALL NOT 存在对它的任何引用
3. WHEN null-ls 被移除 THEN Neovim 启动 SHALL NOT 产生新的错误或警告

### Requirement 8: 消除全局变量泄漏

**User Story:** 作为维护者，我希望配置不污染全局命名空间，避免与插件产生难以排查的冲突。

#### Acceptance Criteria

1. WHEN Neovim 启动完成 THEN `_G.opts` SHALL 为 nil
2. WHEN nvim-cmp 配置加载完成 THEN 配置 SHALL NOT 向 `_G` 写入 `unpack`
3. WHEN user_command 加载完成 THEN `SetDiagnosticSeverity` SHALL NOT 作为全局函数暴露
4. WHERE 已有功能依赖这些名称 THE 重构 SHALL 保持原有行为不变

### Requirement 9: 修正结构与文档缺陷

**User Story:** 作为维护者，我希望配置读起来清晰无误导，文档能正确渲染。

#### Acceptance Criteria

1. WHEN 审阅 `Plugins/lsp/lsp.lua` THEN 重复的同名 `local status_ok` 声明 SHALL 被消除
2. WHEN 判断 mason 是否加载成功 THEN 判断 SHALL 基于 `pcall` 的返回状态
3. WHEN 审阅 `lsp/lua_ls.lua` THEN 缩进错乱的注释块 SHALL 被整理或删除
4. WHEN 渲染 `README.md` THEN 代码块 SHALL 使用正确的三反引号语法
5. WHEN `README.md` 描述编译依赖 THEN 文档 SHALL 反映 tree-sitter CLI 的新要求
6. WHEN `README.md` 描述 zig 的用途 THEN 该说明 SHALL 被更新或移除以反映 main 分支不再使用 zig 编译 parser

### Requirement 10: 优化启动性能

**User Story:** 作为使用者，我希望 Neovim 启动更快，同时不损失任何现有功能。

#### Acceptance Criteria

1. WHEN 使用 `--startuptime` 测量启动耗时 THEN 总耗时 SHALL 低于 200ms（改造前基线为 327ms）
2. WHEN 用户未使用 mason 相关命令 THEN mason SHALL NOT 在启动时被完整加载
3. WHEN 用户首次触发 Telescope 快捷键 THEN telescope SHALL 被正确加载并执行对应动作
4. WHEN 用户首次触发 aerial 快捷键（F4 / Shift-F4）THEN aerial SHALL 被正确加载并执行对应动作
5. WHEN 用户首次执行 CopilotChat 相关命令 THEN 插件 SHALL 被正确加载
6. WHERE 插件被改为懒加载 THE 其原有的按键、命令与行为 SHALL 保持不变
7. IF LSP 服务器需要在打开文件时自动启动 THEN 懒加载 SHALL NOT 破坏该行为
8. WHEN 测量启动耗时 THEN 测量 SHALL 在同一台机器上重复多次取稳定值，避免单次抖动
9. IF 200ms 目标在不牺牲功能的前提下无法达成 THEN 实际结果与瓶颈分析 SHALL 被记录并告知用户

### Requirement 11: 改造过程的安全性与可验证性

**User Story:** 作为使用者，我希望改造过程可控、可回滚，并且每一步都经过验证。

#### Acceptance Criteria

1. WHEN 开始改造前 THEN 当前配置状态 SHALL 可通过 git 恢复
2. WHEN 每个阶段完成 THEN 该阶段的改动 SHALL 通过启动无错误验证
3. WHEN 全部改造完成 THEN `:checkhealth` SHALL NOT 报告由本次改动引入的新错误
4. WHEN 验证过程创建了临时文件 THEN 这些文件 SHALL 在验证结束后被清理
5. IF 某项改动需要用户在系统层面安装依赖 THEN 该依赖 SHALL 被明确告知用户而非静默失败
