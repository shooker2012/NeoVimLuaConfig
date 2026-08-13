# Startup Performance Specification

## Purpose

定义 Neovim 启动性能、懒加载行为及其可重复测量方式。

## Requirements

### Requirement: R10 优化启动性能
系统 SHALL 实现“优化启动性能”。作为使用者，我希望 Neovim 启动更快，同时不损失任何现有功能。

#### Scenario: R10.1 验收条件
- **WHEN** 使用 `--startuptime` 测量启动耗时
- **THEN** 系统 SHALL 报告稳定测量值及其与 367.068ms 可执行基线、327ms 历史参考值和 200ms 尽力目标的差异

#### Scenario: R10.2 验收条件
- **WHEN** 用户未使用 mason 相关命令
- **THEN** mason SHALL NOT 在启动时被完整加载

#### Scenario: R10.3 验收条件
- **WHEN** 用户首次触发 Telescope 快捷键
- **THEN** telescope SHALL 被正确加载并执行对应动作

#### Scenario: R10.4 验收条件
- **WHEN** 用户首次触发 aerial 快捷键（F4 / Shift-F4）
- **THEN** aerial SHALL 被正确加载并执行对应动作

#### Scenario: R10.6 验收条件
- **WHEN** 插件被改为懒加载
- **THEN** 其原有的按键、命令与行为 SHALL 保持不变

#### Scenario: R10.7 验收条件
- **WHEN** LSP 服务器需要在打开文件时自动启动
- **THEN** 懒加载 SHALL NOT 破坏该行为

#### Scenario: R10.8 验收条件
- **WHEN** 测量启动耗时
- **THEN** 测量 SHALL 在同一台机器上重复多次取稳定值，避免单次抖动

#### Scenario: R10.9 验收条件
- **WHEN** 200ms 目标在不牺牲功能的前提下无法达成
- **THEN** 实际结果与瓶颈分析 SHALL 被记录并告知用户

#### Scenario: R10.10 首屏与延迟加载口径
- **WHEN** 使用 `--startuptime` 报告首屏可交互耗时
- **THEN** 系统 SHALL 另行报告 VeryLazy 完成后的补充耗时或加载清单，不得仅通过把工作移到首屏后宣称优化完成

#### Scenario: R10.11 Mason 命令首次调用
- **WHEN** Mason 尚未加载且用户首次执行 `:Mason`、`:MasonInstall`、`:MasonUninstall`、`:MasonUninstallAll`、`:MasonUpdate` 或 `:MasonLog`
- **THEN** lazy.nvim SHALL 加载 Mason 并执行对应命令
