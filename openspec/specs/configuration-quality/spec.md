# Configuration Quality Specification

## Purpose

约束 Neovim 配置的共享状态、代码结构、文档准确性与版本可复现性。

## Requirements

### Requirement: R8 消除非预期全局写入
系统 SHALL 实现“消除非预期全局写入”。作为维护者，我希望配置只保留经过明确约定的共享状态，避免与插件产生难以排查的冲突。

#### Scenario: R8.1 验收条件
- **WHEN** Neovim 启动完成
- **THEN** `_G.opts` SHALL 为 nil

#### Scenario: R8.2 验收条件
- **WHEN** nvim-cmp 配置加载完成
- **THEN** 配置 SHALL NOT 向 `_G` 写入 `unpack`

#### Scenario: R8.3 验收条件
- **WHEN** user_command 加载完成
- **THEN** `SetDiagnosticSeverity` SHALL NOT 作为全局函数暴露

#### Scenario: R8.4 验收条件
- **WHEN** 已有功能依赖这些名称
- **THEN** 重构 SHALL 保持原有行为不变

#### Scenario: R8.5 有意共享状态例外
- **WHEN** 诊断严重程度需要在 `init.lua`、按键和用户命令之间共享
- **THEN** `_G.sal_diagnostic_severity` SHALL 作为唯一允许的项目自定义 `_G` 状态保留，并在 `CONTEXT.md` 中明确记录

### Requirement: R9 修正结构与文档缺陷
系统 SHALL 实现“修正结构与文档缺陷”。作为维护者，我希望配置读起来清晰无误导，文档能正确渲染。

#### Scenario: R9.1 验收条件
- **WHEN** 审阅 `Plugins/lsp/lsp.lua`
- **THEN** 重复的同名 `local status_ok` 声明 SHALL 被消除

#### Scenario: R9.2 验收条件
- **WHEN** 判断 mason 是否加载成功
- **THEN** 判断 SHALL 基于 `pcall` 的返回状态

#### Scenario: R9.3 验收条件
- **WHEN** 审阅 `lsp/lua_ls.lua`
- **THEN** 缩进错乱的注释块 SHALL 被整理或删除

#### Scenario: R9.4 验收条件
- **WHEN** 渲染 `README.md`
- **THEN** 代码块 SHALL 使用正确的三反引号语法

#### Scenario: R9.5 验收条件
- **WHEN** `README.md` 描述编译依赖
- **THEN** 文档 SHALL 反映 tree-sitter CLI 的新要求

#### Scenario: R9.6 验收条件
- **WHEN** `README.md` 描述 zig 的用途
- **THEN** 该说明 SHALL 被更新或移除以反映 main 分支不再使用 zig 编译 parser

#### Scenario: R9.7 规格权威来源
- **WHEN** Kiro 到 OpenSpec 的转换完成
- **THEN** OpenSpec change SHALL 成为唯一维护的规格来源，Kiro 原规格 SHALL 仅作为只读迁移记录并指向 OpenSpec

#### Scenario: R9.8 lockfile 可复现性
- **WHEN** 插件被新增、移除或升级
- **THEN** `lazy-lock.json` SHALL 纳入版本控制并随对应阶段提交
