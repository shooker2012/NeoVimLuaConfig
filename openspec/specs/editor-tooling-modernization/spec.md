# Editor Tooling Modernization Specification

## Purpose

规定 Neovim API、格式化工具链与废弃插件依赖的现代化目标。

## Requirements

### Requirement: R5 替换已移除与已废弃的 API
系统 SHALL 实现“替换已移除与已废弃的 API”。作为使用者，我希望所有按键和命令都能正常工作，并且配置在未来的 Neovim 版本中不会失效。

#### Scenario: R5.1 验收条件
- **WHEN** 用户执行 `:Format` 命令
- **THEN** 系统 SHALL NOT 调用已移除的 `vim.lsp.buf.formatting()`

#### Scenario: R5.2 验收条件
- **WHEN** LSP 客户端挂载
- **THEN** document highlight 的能力判断 SHALL 使用正确的 `documentHighlightProvider` 字段

#### Scenario: R5.3 验收条件
- **WHEN** LSP 客户端支持 document highlight
- **THEN** 对应的 autocmd SHALL 被成功创建

#### Scenario: R5.4 验收条件
- **WHEN** 用户使用 `[d` / `]d` 跳转诊断
- **THEN** 系统 SHALL 使用 `vim.diagnostic.jump()` 而非已废弃的 `goto_prev` / `goto_next`

#### Scenario: R5.5 验收条件
- **WHEN** 诊断跳转发生
- **THEN** 严重程度过滤行为 SHALL 与原有 `_G.sal_diagnostic_severity` 语义保持一致

#### Scenario: R5.6 验收条件
- **WHEN** 配置浮窗边框
- **THEN** 系统 SHALL 使用 `vim.o.winborder` 而非已废弃的 `vim.lsp.with()` 覆盖 handler

#### Scenario: R5.7 验收条件
- **WHEN** 创建 autocmd
- **THEN** 配置 SHALL 使用 `nvim_create_autocmd` 而非已废弃的 `nvim_exec()`

#### Scenario: R5.8 验收条件
- **WHEN** 检测 lazy.nvim 安装路径
- **THEN** 配置 SHALL 使用 `vim.uv` 而非已废弃的 `vim.loop`

#### Scenario: R5.9 验收条件
- **WHEN** 配置诊断浮窗的 source 显示
- **THEN** 取值 SHALL 为合法的 `boolean` 或 `'if_many'`

#### Scenario: R5.10 验收条件
- **WHEN** 判断 TypeScript 语言服务器
- **THEN** 名称比较 SHALL 使用当前名称 `ts_ls`

### Requirement: R6 引入 conform.nvim 提供代码格式化
系统 SHALL 实现“引入 conform.nvim 提供代码格式化”。作为使用者，我希望能对 C/C++ 与 Lua 代码执行格式化，并且格式化入口统一，不依赖已归档的插件。

#### Scenario: R6.1 验收条件
- **WHEN** 用户执行 `:Format` 命令
- **THEN** 系统 SHALL 通过 conform.nvim 执行格式化

#### Scenario: R6.2 验收条件
- **WHEN** 文件类型为 c 或 cpp
- **THEN** conform SHALL 配置 `clang-format` 作为格式化器

#### Scenario: R6.3 验收条件
- **WHEN** 文件类型为 lua
- **THEN** conform SHALL 配置 `stylua` 作为格式化器

#### Scenario: R6.4 验收条件
- **WHEN** 文件类型为 python
- **THEN** conform SHALL 配置可用的格式化器

#### Scenario: R6.5 验收条件
- **WHEN** 文件类型为 rust
- **THEN** 格式化 SHALL 交由 rust_analyzer 的 LSP 格式化能力处理

#### Scenario: R6.6 验收条件
- **WHEN** 某文件类型没有配置外部格式化器
- **THEN** conform SHALL 回落到 LSP 格式化

#### Scenario: R6.7 验收条件
- **WHEN** 配置的格式化器可执行文件缺失
- **THEN** 系统 SHALL 给出可读的提示而非静默失败或抛出堆栈

#### Scenario: R6.8 验收条件
- **WHEN** 用户执行格式化
- **THEN** 格式化 SHALL NOT 自动在保存时触发（保持显式调用）

#### Scenario: R6.9 验收条件
- **WHEN** conform 被引入
- **THEN** 它 SHALL 采用懒加载，不增加启动时的模块加载

#### Scenario: R6.10 验收条件
- **WHEN** 格式化依赖的外部工具未安装
- **THEN** 该依赖 SHALL 被记录到 README 的安装说明中

#### Scenario: R6.11 外部 formatter 安装边界
- **WHEN** `clang-format`、`stylua`、`ruff` 或 `black` 未安装
- **THEN** 本任务 SHALL NOT 自动安装这些系统程序，实际格式化成功路径 MAY 记录为“未验证”，但缺失提示与无堆栈行为仍 SHALL 通过验收

#### Scenario: R6.12 formatter 通知配置
- **WHEN** conform 配置完成
- **THEN** `notify_on_error` 与 `notify_no_formatters` SHALL 被显式启用而非依赖插件默认值

### Requirement: R7 移除归档的死依赖
系统 SHALL 实现“移除归档的死依赖”。作为使用者，我不希望为从未使用的插件付出加载开销。

#### Scenario: R7.1 验收条件
- **WHEN** 审阅插件列表
- **THEN** `jose-elias-alvarez/null-ls.nvim` SHALL 被移除

#### Scenario: R7.2 验收条件
- **WHEN** null-ls 被移除
- **THEN** 配置中 SHALL NOT 存在对它的任何引用

#### Scenario: R7.3 验收条件
- **WHEN** null-ls 被移除
- **THEN** Neovim 启动 SHALL NOT 产生新的错误或警告

#### Scenario: R7.4 移除 Copilot 插件
- **WHEN** 审阅插件列表与 lockfile
- **THEN** `copilot.lua`、`copilot-cmp` 与 `CopilotChat.nvim` SHALL 全部被移除

#### Scenario: R7.5 移除 Copilot 配置
- **WHEN** Copilot 集成被移除
- **THEN** nvim-cmp 的 `copilot` source/menu、`CC` 缩写以及 OpenSpec/测试夹具中的 Copilot 验收入口 SHALL 不再存在

#### Scenario: R7.6 本机缓存边界
- **WHEN** Copilot 和 null-ls 不再被插件管理器声明
- **THEN** 本任务 SHALL NOT 主动删除 `nvim-data/lazy` 中已下载的插件目录，缓存清理由用户后续运行 `:Lazy clean` 决定
