## Why

当前配置已经锁定 `nvim-treesitter` 的 `main` 分支，但仍调用 `master` 时代的配置 API，导致 parser 安装、高亮、折叠和 matchup 集成整体失效。同时，Neovim 0.11 下仍存在已移除或已废弃 API、归档/不再需要的依赖、非预期全局写入以及不必要的启动期加载，需要在继续演进前统一治理。

## What Changes

- 将 treesitter 配置迁移到 `main` 分支 API，恢复 parser 安装、语法高亮、折叠和 vim-matchup/textobjects 集成。
- 使用 Neovim 0.11 原生 API 替换已移除或已废弃的 LSP、诊断、autocmd、浮窗和 libuv 调用。
- 引入懒加载的 `conform.nvim` 统一显式格式化入口，移除未使用且已归档的 `null-ls.nvim`，并完整移除 Copilot、CopilotChat 及其补全集成。
- 消除非预期全局写入，保留并记录有意的 `_G.sal_diagnostic_severity` 共享状态，整理 LSP/filetype/README 结构缺陷，并补充自动化验证脚本。
- 在阶段 checkpoint 生成可直接用 Neovim 打开的手工验证夹具和操作清单，由用户亲自确认高亮、折叠、LSP、格式化、按键与懒加载体验。
- 调整 mason、Telescope、aerial、nvim-cmp 等插件的加载时机，在保持既有按键和自动 LSP 行为的前提下，将首屏可交互耗时由本次可执行基线 367.068ms 尽力降至 200ms 以下；327ms 仅保留为历史参考值，并单独报告 VeryLazy 后的补充加载。
- 明确四项有意的行为变化：移除全部 Copilot 能力；默认浮窗边框统一为 `rounded`，并要求在用户日常 Windows Terminal 宿主中验收；`.fx`/`.shader` 使用 `hlsl`、`.vsh` 使用 `glsl`；命令行与搜索模式启用补全弹窗。

## Capabilities

### New Capabilities

- `treesitter-modernization`: 定义 treesitter parser 安装、高亮、折叠、textobjects、matchup 与 shader filetype 的预期行为。
- `editor-tooling-modernization`: 定义 Neovim 0.11 API 迁移、conform 格式化以及移除 null-ls/Copilot 后的行为契约。
- `configuration-quality`: 定义全局命名空间、LSP 配置结构和 README 文档质量要求。
- `startup-performance`: 定义插件懒加载、自动 LSP 保持和启动性能测量目标。
- `migration-verification`: 定义改造过程的可回滚性、分阶段验证、health 检查和外部依赖提示。

### Modified Capabilities

无。当前仓库尚无已归档的 OpenSpec capability，本次从现有 Kiro spec 建立首批能力规格。

## Impact

- 主要影响 `init.lua`、`lua/plugin_manager.lua`、`lua/Plugins/treesitter.lua`、`lua/Plugins/lsp/*`、`lua/keymaps.lua`、`lua/user_command.lua`、`lsp/lua_ls.lua` 和 `README.md`。
- 新增 `lua/Plugins/textobjects.lua`、`lua/Plugins/conform.lua` 以及验证/启动测量脚本。
- 新增运行依赖 `tree-sitter` CLI；格式化功能按语言选择性依赖独立安装且位于 PATH 的 `clang-format`、`stylua`、`ruff` 或 `black`。本任务不自动安装这些外部程序，缺失时实际格式化可记为“未验证”而不阻塞其余改造。
- `nvim-treesitter/main` 尚未稳定，后续 `:Lazy update` 可能带来 API 兼容风险；版本仍由 `lazy-lock.json` 锁定。
- `lazy-lock.json` 纳入版本控制，用于审查和复现插件版本变化；本机 `nvim-data/lazy` 下不再使用的插件缓存不由本任务主动删除。
