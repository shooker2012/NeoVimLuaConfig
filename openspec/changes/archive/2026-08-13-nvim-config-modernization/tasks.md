> 本任务清单由 Kiro spec 迁移而来；OpenSpec 是当前唯一实施依据，原 Kiro 文档仅保留为只读历史输入。

按设计文档的六个阶段推进：① 恢复 treesitter ② filetype 规则迁移 ③ 废弃 API 迁移 ④ conform 接管格式化并移除 null-ls 与 Copilot ⑤ 非预期全局写入与结构清理 ⑥ 懒加载与文档。

实现语言为 Lua（Neovim 配置），验证脚本为 Lua（`nvim --headless -l`）与 PowerShell（启动耗时测量）。设计文档没有 Correctness Properties 章节，验证以 Testing Strategy 中的断言矩阵为准，落在 `verify.lua` 与 `check_startup.ps1` 两个可执行脚本上。

每个阶段结束提交一次 git，便于单点回退（R11.1）。

只有能通过启动 Neovim、打开代表性文件并执行编辑器内操作直接观察结果的任务才需要人工验收。纯规格、Git 基线、验证脚本、静态断言、内部状态、性能报告或文档任务在自动检查通过后直接完成，不要求用户审阅内部实现或命令输出。相关行为可复用阶段套件；用户确认结果归档到 `verification/<任务编号>.md`，生成夹具保持忽略且可清理（R11.6、R11.10-R11.12）。

## Neovim 可观察行为人工验收矩阵

人工验收包生成到 `manual-tests/<套件>/`。用户按其中的 `TESTING.md` 启动 Neovim、打开文件并操作后，只需在对话中反馈“通过”、失败项和备注；实施者据此生成受版本控制的结果摘要。下表只列需要人工观察的阶段，其余任务由自动检查完成。

| Checkpoint | 套件 | 可直接观察的效果 |
| --- | --- | --- |
| 4.1 | `treesitter` | 打开 C++、Lua、shader、Markdown，检查 filetype、高亮、折叠、matchup、context 与 textobjects |
| 7.1 | `tooling` | 打开 C++、Lua、Python、Rust，检查 LSP 浮窗、诊断跳转、`:Format`、范围格式化与缺失工具提示 |
| 11.1 | `lazy-loading` / `all` | 打开代表性文件，检查自动 LSP、命令行补全、Telescope、aerial、hop、浮窗边框和首次加载行为 |

## 0. 前置依赖与决策记录

- [x] 0.1 确认前置依赖与记录架构决策
  - tree-sitter CLI 已安装（0.26.11，满足 `health.lua` 要求的 0.26.1）；R1.1 / R1.4 由此变为可验收
  - `docs/adr/0001-nvim-treesitter-main-branch.md` 已记录「采用 main 分支」的权衡
  - 格式化工具（clang-format / stylua / ruff / black）是独立外部可执行文件，本次不自动安装；配置与缺失提示必须可验收，实际格式化成功可因外部环境记为“未验证”
  - `docs/adr/0002-mason-managed-lsp-binaries.md` 记录 lua_ls / pyright / rust_analyzer 统一由 Mason 管理
  - _Requirements: 1.1, 11.5_

- [x] 0.2 建立迁移基线提交
  - 将当前可复现状态提交为迁移基线，包含受版本控制的 `lazy-lock.json` 与现有文档；不得忽略 lockfile
  - 记录 `check_startup.ps1` 的可执行基线 367.068ms；327ms 仅作为历史参考值
  - 后续每个阶段单独提交，确保 checkpoint 可单点回退
  - _Requirements: 10.1, 11.1, 11.3_

## 1. 建立可执行的验证基线
- [x] 1.1 创建 `openspec/changes/nvim-config-modernization/verify.lua` 断言框架
    - 提供 `assert_eq` / `assert_true` / `assert_no_match_in_files` 等 helper，收集失败项并在末尾统一输出
    - 提供仓库文件遍历 helper（限定 `init.lua`、`lua/**`、`lsp/**`），供后续 grep 类断言复用
    - 以非零退出码表示存在失败断言，通过 `nvim --headless -l` 执行
    - 脚本自身产生的临时文件在结束前删除
    - _Requirements: 11.2, 11.4_

- [x] 1.2 创建 `openspec/changes/nvim-config-modernization/check_startup.ps1`
    - 执行 `nvim --headless -c "messages" -c "qa!"`，在输出中匹配 `E\d+` / `Error` / `deprecated` 并报告
    - **不打开任何文件**：设计文档已记录 headless 下 lua_ls 以 exit code 1 退出、错误消息触发无人应答的 hit-enter 提示导致进程永久挂起；8.4 让 `vim.lsp.enable` 进入启动路径后，一旦打开文件即触发 server，风险更高
    - 执行 `nvim --startuptime` 连续 5 次，丢弃首次，输出中位数总耗时
    - 每次调用带超时并在超时后强制结束进程，避免 headless 挂起时无限等待
    - 临时的 startuptime 日志文件在结束前删除
    - _Requirements: 10.1, 10.8, 11.2, 11.4_

- [x] 1.3 创建 `generate_manual_tests.ps1` 与人工验证说明模板
    - 支持 `treesitter`、`tooling`、`lazy-loading`、`all` 套件，生成过程幂等且只操作专用输出目录
    - 每个套件生成代表性源码、必要的最小项目文件和 `TESTING.md`，写明打开方式、操作步骤、预期现象及结果记录栏
    - treesitter 套件覆盖 C++、Lua、HLSL、FX、GLSL、Markdown；tooling 套件覆盖 C++、Lua、Python 与最小 Rust project
    - lazy-loading 套件覆盖 normal/visual/operator 模式按键、命令、LSP 浮窗与插件首次加载
    - _Requirements: 11.2, 11.4, 11.6, 11.7_

- [x] 1.4 加固验证脚本的生命周期与幂等性
    - `verify.lua` 用受保护的 finally 风格路径清理临时文件，成功、失败或异常退出均不留残留
    - `generate_manual_tests.ps1` 每次重建所选套件目录，移除上一轮遗留文件；生成目录保持临时或忽略，仅提交 checkpoint 结果摘要
    - 只为 `treesitter`、`tooling`、`lazy-loading` 与 `all` 可观察行为套件生成夹具；不为规格、Git、脚本、断言、内部状态、性能或文档任务生成空壳人工验收包
    - 用户确认可观察行为后将结果归档到 `verification/<checkpoint>.md`
    - _Requirements: 11.4, 11.6, 11.7, 11.8, 11.9, 11.10, 11.11, 11.12_

## 2. 恢复 treesitter 功能（阶段 ①）
- [x] 2.1 重写 `lua/Plugins/treesitter.lua`
    - 定义 `M.languages`（c、cpp、lua、rust、python、vim、vimdoc、query、glsl、hlsl、markdown、markdown_inline、json、bash）与 `M.filetypes`
    - `setup()` 中调用 `require("nvim-treesitter").setup({ install_dir = stdpath("data").."/site" })`；**不需要** `vim.treesitter.language.register`，因为 3.1 已把自定义 filetype `fx` 改名为 `hlsl`，与 parser 名直接一致
    - `M.filetypes` 中对应项写 `hlsl`（不再是 `fx`）
    - `install_async()`：开头先判 `#vim.api.nvim_list_uis() == 0`（headless）则直接返回，避免 `nvim --headless` 验证时触发 14 个 grammar 的下载编译（要么被 `qa!` 中断导致装半截，要么让每次验证跑几分钟）；用 UI 判定而非自定义环境变量，可对 `nvim --headless -l verify.lua` 自动生效
    - 其次 `vim.fn.executable("tree-sitter") == 0` 时仅 `vim.notify` WARN 并返回；否则用 `require("nvim-treesitter.config").get_installed("parsers")` 过滤缺失项，再在 `vim.schedule` 中 `install(missing, { summary = true })`
    - `attach_autocmd()`：FileType autocmd 中 `pcall(vim.treesitter.language.add, lang)` 探测可用性，成功则 `vim.treesitter.start`，并设置 `vim.wo[0][0].foldmethod = "expr"` 与 `vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"`
    - 删除 master 时代的 `ensure_installed` / `sync_install` / `auto_install` / `ignore_install` / `highlight` / `indent` / `matchup` 字段与全局 `vim.o.foldmethod` / `vim.o.foldexpr`
    - _Requirements: 1.3, 1.5, 1.6, 1.7, 1.8, 2.1, 2.3, 2.4, 3.2, 3.3, 3.4, 4.1_

- [x] 2.2 新增 `lua/Plugins/textobjects.lua`
    - 将 textobjects 配置从 `treesitter.lua` 拆出，`setup()` 只传 `select = { lookahead, include_surrounding_whitespace }`，不再传 `keymaps`
    - 用 `M.mappings` 作为映射的唯一来源，`as` 统一为 `@local.scope` + `locals`，循环注册 `{ "x", "o" }` 映射
    - `require` 失败时 `pcall` 静默返回
    - _Requirements: 4.2, 4.3_

- [x] 2.3 在 `lua/plugin_manager.lua` 中调整 treesitter 相关插件声明
    - treesitter 声明显式补上 `branch = "main"`（当前依赖上游默认分支的隐式行为），与 textobjects 的声明风格一致；不 pin commit，版本仍由 `lazy-lock.json` 锁定
    - treesitter 的 `config` 改为调用 `require("Plugins.treesitter").setup()`
    - textobjects 的 `config` 改为调用 `require("Plugins.textobjects").setup()`
    - 移除重复声明的 `andymass/vim-matchup`，保留单一启动期声明（`lazy = false`，避免 `VimEnter` 晚于首个 `FileType` 而漏初始化），并在 `init` 中设置 `matchup_matchparen_offscreen`、`matchup_treesitter_enabled`、`matchup_treesitter_disabled`
    - _Requirements: 4.4, 4.5_

- [x] 2.5 为 `nvim-treesitter-context` 补上显式配置与懒加载
    - 当前是裸字符串声明，lazy 不调 `config`，靠插件自带 `plugin/treesitter-context.lua` 默认启用 —— 处于「已加载但从未被配置」状态
    - 改为表形式声明，`event = "VeryLazy"`，并传 `opts = { enable = true, max_lines = 0, mode = "cursor" }`，使启用意图在配置中可见
    - 它不 require `nvim-treesitter`，直接用原生 `vim.treesitter`，与 main 分支迁移无冲突；但依赖 2.1 的 `treesitter.start()` 已附加 parser 才能显示上下文
    - _Requirements: 10.6_

- [x] 2.4 在 `verify.lua` 中补充 treesitter 与 filetype 断言
    - runtimepath 包含 `stdpath("data").."/site"`（R1.2）；`get_installed("parsers")` 覆盖目标列表（R1.4）
    - R1.8 改为断言 `vim.filetype.match({ filename = "a.hlsl" }) == "hlsl"` 与 `vim.filetype.match({ filename = "a.fx" }) == "hlsl"`（原 `get_lang("fx")` 断言随 `fx` 改名作废）
    - 同时断言 `vim.filetype.match({ filename = "a.vsh" }) == "glsl"` 与 `vim.filetype.match({ filename = "a.shader" }) == "hlsl"`，锁定对内置检测的有意覆盖
    - 打开临时 `.cpp` 后 `vim.treesitter.highlighter.active[buf] ~= nil`（R2.2）
    - `vim.wo.foldexpr` 含 `vim.treesitter.foldexpr` 且求值不报 E117（R3.1、R3.2）
    - grep `treesitter.lua` 不含 `ensure_installed`/`highlight`/`auto_install`/`matchup`/`indent`（R4.1）
    - 断言 textobjects 的 `as` 映射只有一个来源，setup 无 `keymaps`；vim-matchup 只声明一次且集成选项来自自身配置（R4.2-R4.5）
    - 断言 treesitter-context 为显式 `VeryLazy` 配置，避免裸声明产生隐式行为（R10.6）
    - 断言 headless 会跳过 parser 下载/编译，而 UI 会异步补齐缺失 parser
    - _Requirements: 1.2, 1.4, 1.8, 1.9, 1.10, 2.2, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 4.5, 10.6_

## 3. 迁移 filetype 规则（阶段 ②）
- [x] 3.1 在 `init.lua` 中用 `vim.filetype.add` 替换两条 `au BufNewFile,BufRead`
    - **自定义 filetype `fx` 改名为 `hlsl`**：已确认 `syntax/fx.vim` 与 `syntax/hlsl.vim` 均不存在，`.hlsl` / `.fx` 文件当前完全没有高亮；改用 `hlsl` 后与 treesitter parser 名一致，parser 自动匹配，无需 `language.register`
    - 已确认仓库内无任何配置依赖 `fx` 这个名字（无 `ftplugin/fx.*`、无 `fx.snippets`），改名代价为零
    - glsl 扩展名：frag、vert、fp、vp、glsl、fsh、vsh
    - hlsl 扩展名：hlsl、fx、fxh、psh、shader
    - 以下四项是对 Neovim 内置 filetype 检测的有意覆盖，需在代码注释中写明：`vsh` 内置为 `v`（V 语言）改判 glsl；`fsh` 内置为 `fsh` 改判 glsl；`shader` 内置为 `gdshader`（Godot）改判 hlsl（用户当前不使用 Godot）；`psh` 内置无归属
    - `vsh` 在原两条 `au` 中重复出现（实际被 fx 覆盖），现统一归 glsl，属行为变化
    - 注册位置置于 `require "keymaps"` 之前，确保 treesitter 的 FileType autocmd 能正确捕获
    - _Requirements: 1.7, 1.8, 1.10_

## 4. Checkpoint - treesitter 与 filetype

- [x] 4.1 完成“Checkpoint - treesitter 与 filetype”阶段检查点
  - **先带 UI 手动启动一次 nvim**，等 `install()` 的 summary 显示 14 个 parser 装完（headless 会跳过安装，这一步不能省，否则 R1.4 与 R2.2 的断言必然失败）
  - 运行 `check_startup.ps1` 与 `verify.lua`，全部自动化断言通过后生成 `treesitter` 人工验证套件
  - 请用户用 Neovim 打开生成的 C++/Lua/shader/Markdown 文件，按 `TESTING.md` 检查高亮、折叠、matchup、context、textobjects 与 filetype，并记录结果
  - 清理生成套件，只提交 checkpoint 结果摘要；自动化、启动、目标行为或回归存在真实失败时不得进入下一阶段，只有外部环境不可用项可标记“未验证”

## 5. 迁移已移除与已废弃的 API（阶段 ③）
- [x] 5.1 改造 `lua/Plugins/lsp/handlers.lua`
    - 删除两处 `vim.lsp.with()` handler 覆盖，改为 `vim.o.winborder = "rounded"`；最终人工验收应从用户日常 Windows Terminal profile 启动，避免自动化环境另起 conhost 导致圆角字符宽度错位
    - 注意 `winborder` 是全局选项，影响面超出 LSP：所有未显式传 `border` 的 `nvim_open_win` 浮窗都会变（如 telescope 部分窗口、neo-tree 弹窗、hop 提示）；`nvim-cmp` 已显式 `cmp.config.window.bordered()`（single），不受全局默认值影响
    - 诊断 `float.source` 由 `"always"` 改为 `true`，移除 `float.border`
    - `lsp_highlight_document` 判定改用 `client.server_capabilities.documentHighlightProvider`，签名接收 `bufnr`
    - 用 `nvim_create_augroup("sal_lsp_document_highlight_"..bufnr, { clear = true })` + 两个 `nvim_create_autocmd`(CursorHold / CursorMoved) 替换 `nvim_exec` 的 vimscript augroup
    - `on_attach` 中的 server 名称判断由 `tsserver` 改为 `ts_ls`
    - _Requirements: 5.2, 5.3, 5.6, 5.7, 5.9, 5.10_

- [x] 5.2 改造 `lua/keymaps.lua` 的诊断跳转
    - `[d` / `]d` 改用 `vim.diagnostic.jump({ count = -1/1, float = ... })`，保留 `severity = { min = _G.sal_diagnostic_severity }` 过滤语义
    - _Requirements: 5.4, 5.5_

- [x] 5.3 将 `lua/plugin_manager.lua` 中的 `vim.loop.fs_stat` 改为 `vim.uv.fs_stat`
    - _Requirements: 5.8_

## 6. 引入 conform，并移除 null-ls 与 Copilot（阶段 ④）
- [x] 6.1 新增 `lua/Plugins/conform.lua`
    - `formatters_by_ft`：c/cpp 用 `clang-format`，lua 用 `stylua`，python 用 `{ "ruff_format", "black", stop_after_first = true }`；rust 不配置外部格式化器
    - `M.setup()` 只负责 `require("conform").setup({...})`，传入 `default_format_opts = { lsp_format = "fallback" }`、`format_on_save = false`、`notify_on_error = true` 与 `notify_no_formatters = true`；**不在此处注册 `:Format`**
    - 另外暴露 `M.register_command()`：用 `nvim_create_user_command("Format", ..., { range = true })` 手动注册，命令体内才 `require("conform").format({ async = true, lsp_format = "fallback", range = range })`
    - `range` 由 `args.count ~= -1` 判断，构造 `{ start = { args.line1, 0 }, ["end"] = { args.line2, math.huge } }`
    - 命令注册与 conform 加载解耦：注册发生在启动期，`require("conform")` 发生在首次执行时；否则「命令定义在 setup 里、setup 又要靠命令触发」会形成死锁
    - 不下载或安装 clang-format / stylua / ruff / black；工具缺失时必须给出可读通知，实际格式化成功允许因外部工具不可用记为“未验证”
    - _Requirements: 5.1, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.11, 6.12_

- [x] 6.2 从 `lua/Plugins/lsp/handlers.lua` 移除旧的 `:Format` 定义
    - 删除 `lsp_keymaps` 中的 `vim.cmd [[ command! Format ... vim.lsp.buf.formatting() ]]`
    - _Requirements: 5.1, 6.1_

- [x] 6.3 在 `lua/plugin_manager.lua` 中声明 conform，并删除 null-ls 与 Copilot
    - 新增 `stevearc/conform.nvim`，仅以 `cmd = "ConformInfo"` 懒加载，`config` 调用 `require("Plugins.conform").setup()`
    - **不要**把 `Format` 放进 lazy 的 `cmd` 列表：lazy 占位命令对 `range` 属性的透传不确定，`:'<,'>Format` 首次调用可能丢掉行范围
    - 在 `init` 中调用 `require("Plugins.conform").register_command()`，使 `:Format` 在启动期即存在且 `range = true` 语义完全自控
    - 已验证安全：lazy 的 `loader.M.auto_load` 会 hook 未加载插件的 `require`，命令体内 `require("conform")` 先触发该插件 `config`（即 `setup()`）再返回模块，因此首次 `:Format` 能拿到已配置的 `formatters_by_ft`，不会在未配置状态下回落 LSP
    - 删除 `jose-elias-alvarez/null-ls.nvim` 声明，并确认仓库中无任何 null-ls 引用
    - 删除 `zbirenbaum/copilot.lua`、`zbirenbaum/copilot-cmp`、`CopilotC-Nvim/CopilotChat.nvim` 的插件声明和配置文件
    - 从 nvim-cmp 删除 `copilot` source 与菜单项，删除 `CC` abbrev，并从 OpenSpec、人工测试与 `lazy-lock.json` 删除相应引用
    - `lazy-lock.json` 继续受版本控制；不主动删除 `stdpath("data")/lazy` 中的本地插件缓存，用户可之后通过 lazy.nvim 清理
    - _Requirements: 6.9, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [x] 6.4 在 `verify.lua` 中补充废弃 API 与格式化断言
    - grep 全仓库无 `buf.formatting`、`goto_prev`、`goto_next`、`vim.loop`、`nvim_exec(`、`documentHighlight` 非 Provider 形式、`tsserver`、`source = "always"`、`vim.lsp.with`（R5.1-5.10）
    - `vim.fn.exists(":Format") == 2` 且 `conform` 可 require（R6.1）
    - 检查 `formatters_by_ft`、`lsp_format = "fallback"`、`format_on_save = false`、两个 notify 开关、命令 range 属性及启动期 `package.loaded.conform == nil`（R6.2-R6.12）
    - 对缺失 formatter 的测试文件调用 `:Format`，确认产生可读通知且无 Lua 堆栈（R6.7）
    - grep 实现代码、插件声明、配置、人工测试与 lockfile 均无 `null-ls`、`copilot`、`CopilotChat` 和 `CC` abbrev（历史迁移文档中的说明除外）
    - 启动验证确认移除 null-ls 与 Copilot 后无新增错误、deprecated；既有无关 WARNING 只记录不阻断
    - _Requirements: 5.1-5.10, 6.1-6.12, 7.1-7.6_

## 7. Checkpoint - API 迁移与格式化

- [x] 7.1 完成“Checkpoint - API 迁移与格式化”阶段检查点
  - 运行 `check_startup.ps1` 与 `verify.lua`，确保启动无错、无 deprecated 警告
  - 生成 `tooling` 人工验证套件，请用户打开 C++/Lua/Python/Rust 文件，检查 `:Format`、范围格式化、缺失工具提示和三个 LSP client，并记录结果；独立 formatter 不可用时只将实际格式化成功记为“未验证”，缺失提示失败仍阻断
  - 清理生成套件并提交结果摘要；自动化、启动、目标行为或回归存在真实失败时不得进入下一阶段

## 8. 清理非预期全局写入与结构缺陷（阶段 ⑤）
- [x] 8.1 消除 `lua/plugin_manager.lua` 中的 `_G.opts`
    - 删除裸 `opts = { rocks = ... }` 赋值，改为 `require("lazy").setup(plugins, { rocks = { enabled = false } })`
    - _Requirements: 8.1, 8.4_

- [x] 8.2 消除 `lua/Plugins/nvim-cmp.lua` 中的 `_G.unpack` 写入
    - 在文件顶部声明 `local unpack = unpack or table.unpack`，函数体内改用该局部变量
    - _Requirements: 8.2, 8.4_

- [x] 8.3 将 `lua/user_command.lua` 的 `SetDiagnosticSeverity` 改为 `local function`
    - 命令注册处引用不变，保持读写 `_G.sal_diagnostic_severity` 与 `vim.diagnostic.config` 的既有行为
    - _Requirements: 8.3, 8.4_

- [x] 8.4 重写 `lua/Plugins/lsp/lsp.lua` 为显式启用模式
    - 消除重复的同名 `local status_ok`，mason 相关加载判断基于各自的 `pcall` 返回状态
    - 暴露 `M.servers = { "lua_ls", "pyright", "rust_analyzer" }`，`setup()` 中先 `require("Plugins.lsp.handlers").setup()` 再 `vim.lsp.enable(M.servers)`，不再依赖 mason-lspconfig 的 `automatic_enable`
    - 将 mason / mason-lspconfig 的 setup 从本文件移出（交由插件声明的懒加载 config 处理），保证启动路径不加载 mason
    - **必须在 `vim.lsp.enable` 之前手动把 `stdpath("data").."/mason/bin"` 前置注入 `vim.env.PATH`**：该注入原本由 `mason.setup()` 内的 `global_location:set_env{ PATH = ... }` 完成，mason 改懒加载后启动时不再执行；`mason/bin` 现有 `lua-language-server.cmd`、`pyright-langserver.cmd`，而 lspconfig 的 `lsp/*.lua` 中 `cmd` 是不带路径的可执行名，缺少注入会导致 lua_ls / pyright 静默不挂载（`vim.lsp.enable` 不报错）
    - 注入前用 `vim.uv.fs_stat` 判断目录存在，避免在无 mason 的机器上污染 PATH；注意 Windows 分隔符为 `;`
    - server 配置定义无需自建占位文件：lspconfig 的 `lsp/` 目录已提供 `lua_ls.lua` / `pyright.lua` / `rust_analyzer.lua`，本仓库 `lsp/lua_ls.lua` 仅做 `settings` 覆盖，由 runtimepath 合并
    - _Requirements: 9.1, 9.2, 10.2, 10.7_

- [x] 8.5 整理 `lsp/lua_ls.lua` 中缩进错乱的注释块
    - 删除或对齐失效注释，不改动生效的配置内容
    - _Requirements: 9.3_

- [x] 8.7 在 `lua/Plugins/nvim-cmp.lua` 中启用命令行补全（范围新增）
    - 现状：`cmp-cmdline` 已安装并加载，但 `nvim-cmp.lua` 中没有任何 `cmp.setup.cmdline()` 调用，属于「装了但从未配置」
    - 为 `:` 配置 `cmdline` + `path` source，为 `/` 与 `?` 配置 `buffer` source
    - cmdline 映射用 `cmp.mapping.preset.cmdline()`，不要复用 insert 模式那份自定义 `mapping`（其中 `<Tab>` 依赖 UltiSnips、`<CR>` 语义为确认补全，在命令行会阻碍命令执行）
    - 显式断言 `native_menu = false`，保证命令行补全使用 cmp 菜单而非原生 wildmenu
    - 这是新增功能而非等价迁移，会改变输入 `:` 与 `/` 时的交互（出现补全弹窗）
    - _Requirements: 10.6_

- [x] 8.6 在 `verify.lua` 中补充全局变量、LSP 与命令行补全断言
    - `_G.opts == nil`、`_G.SetDiagnosticSeverity == nil`
    - 静态检查 `nvim-cmp.lua` 不存在非局部 `unpack = ...` 赋值；LuaJIT 原生 `_G.unpack` 允许继续存在
    - `:SetDiagnosticSeverity` 命令仍存在且可调用，`_G.sal_diagnostic_severity` 语义不变
    - 断言 `_G.sal_diagnostic_severity` 是唯一被文档承认的项目级 `_G` 共享状态，且无其他非预期全局写入
    - 断言 mason bin 已前置到 PATH，lua_ls/pyright/rust_analyzer 的命令可执行，且 `vim.lsp.is_enabled()` 状态正确
    - 触发 `CmdlineEnter` 后检查 `:`、`/`、`?` 的 cmp source 与 preset，不复用 insert 模式 mapping，并确认 `native_menu = false`
    - _Requirements: 8.1-8.5, 9.1-9.3, 10.6, 10.7_

## 9. 优化启动性能（阶段 ⑥）
- [x] 9.1 在 `lua/plugin_manager.lua` 中将 mason 相关插件改为懒加载
    - mason 改 `cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonUpdate", "MasonLog" }`，mason-lspconfig 作为其 dependency 并在 config 中执行 `ensure_installed`
    - `ensure_installed` 保留 `{ "lua_ls", "pyright", "rust_analyzer" }`，三者统一由 Mason 管理
    - 即使 PATH 或 rustup 已提供同名命令，也不作为 fallback；通过前置 mason bin，明确让三个 server 都使用 Mason 管理的可执行文件
    - 保持 `require("Plugins.lsp.lsp").setup()` 在启动路径上执行，确保打开文件时 LSP 仍自动启动
    - 验收：懒加载后打开 `.lua`、`.py`、`.rs` 文件，`:lua =vim.lsp.get_clients()` 应分别返回已挂载的 client（依赖 8.4 的 PATH 注入）
    - _Requirements: 10.2, 10.6, 10.7_

- [x] 9.2 在 `lua/plugin_manager.lua` 中将其余插件改为懒加载
    - telescope 的 `keys` 必须用带 `mode` 的表形式，逐个对齐 `Plugins/telescope.lua` 里的真实模式：`<C-p>` / `<C-f>` / `<C-b>` 为 `mode = { "n", "v" }`，`<F3>` 为 `mode = { "n", "v" }`（normal 版搜索光标下单词、visual 版搜索选中内容，是两个不同函数）
    - 裸字符串形式的 `keys` 只注册 normal 模式，会让 visual 模式下的上述按键失去触发能力且不报错 —— 这是 R10.6 的硬性验收点
    - aerial：`keys = { "<F4>", "<S-F4>" }`（已确认仅 normal 模式，可用裸字符串）
    - hop.nvim：`keys = { { "s", mode = "" } }` —— 原代码是 `vim.keymap.set("", "s", ...)`，空字符串对应 n/v/o 三模式，`mode = ""` 必须照写，不能省
    - Comment.nvim：由 `lazy = false` 改为 `event = "VeryLazy"`（`gc` / `gb` 是 operator 映射，VeryLazy 足够）
    - nvim-cmp 及其 sources：`event = { "InsertEnter", "CmdlineEnter" }` —— 必须包含 `CmdlineEnter`，否则 8.7 新增的命令行补全在未进入过插入模式时不会触发
    - tabular / vim-exchange / vim-abolish / vim-mark：`event = "VeryLazy"`
    - 完成后逐个手工确认：normal 与 visual 两种模式下按每个键都能正确加载插件并执行原动作
    - _Requirements: 10.3, 10.4, 10.6_

- [x] 9.3 在 `check_startup.ps1` 中加入基线对比与瓶颈报告
    - 与本机本脚本得到的 367.068ms 可执行基线及 200ms 目标对比；327ms 只显示为历史参考值，不参与回归判定
    - **200ms 为尽力目标而非硬门槛**（用户已确认）：达不到即按 R10.9 输出瓶颈分析并收工，不为压到 200ms 而牺牲功能或改动自有插件
    - 未达标时解析 startuptime 日志，输出 self 耗时最高的前若干项作为瓶颈记录
    - 主指标是首屏交互启动耗时；另记录 `VeryLazy` 后补充工作耗时，避免把延期工作误算成优化收益
    - 已知无法懒加载的硬下限：`tokyonight`（视觉必需）、`ultisnips`（vimscript）、`sal-proj-lua` 与 `sal-custom-macro`（用户自有插件，本次不动）、`treesitter`（需注册 FileType autocmd）、`lualine`
    - 若瓶颈指向 `sal-proj-lua` / `sal-custom-macro`，只报告不改动，交由用户决定
    - _Requirements: 10.1, 10.8, 10.9, 10.10_

## 10. 更新文档
- [x] 10.1 修正 `README.md`
    - 修复代码块的三反引号语法
    - 编译依赖改为 tree-sitter CLI（含 `npm install -g tree-sitter-cli`），移除或改写 zig 用于编译 parser 的说明
    - 说明 clang-format / stylua / ruff / black 是与 Neovim 独立的外部可执行文件，配置不会自动安装它们；给出可选安装说明
    - 说明 lua_ls / pyright / rust_analyzer 统一由 Mason 管理，mason 改懒加载后新机器需手动 `:Mason` 安装
    - _Requirements: 6.10, 9.4, 9.5, 9.6, 11.5_

## 11. Final checkpoint - 全量验证与清理

- [x] 11.1 完成“Final checkpoint - 全量验证与清理”阶段检查点
  - 运行 `verify.lua` 全部断言与 `check_startup.ps1`；按稳定摘要签名比较 `:checkhealth`（含 `nvim-treesitter`、`vim.lsp`），不得新增 ERROR 或 deprecated，既有无关 WARNING 可保留但必须报告
  - **人工视觉回归检查**（脚本无法断言）：从用户日常 Windows Terminal profile 启动 Neovim，逐个打开 LSP hover（`K`）、signature help（`<C-k>`）、diagnostic float（`<Leader>e`）、telescope（`<C-p>`）、neo-tree 弹窗、hop 提示（`s`），确认 `winborder = "rounded"` 未导致任何浮窗外观异常或错位；不得以自动化环境另起的独立 conhost 作为最终视觉验收宿主
  - **人工按键回归检查**：normal 与 visual 两种模式下逐个测试 `<C-p>` / `<C-f>` / `<C-b>` / `<F3>` / `<F4>` / `<S-F4>`，以及 `:Format` 与 `:'<,'>Format`
  - 生成 `lazy-loading`（或 `all`）人工验证套件，请用户按 `TESTING.md` 完成最终体验验收并记录通过、失败、未验证项；套件不得包含 Copilot 场景
  - 删除验证过程产生的临时文件，只提交结果摘要；确认工作区只剩预期改动
  - 自动化、启动、目标行为或回归存在真实失败时不得完成 checkpoint；只有外部环境不可用项可记为“未验证”
  - _Requirements: 1.1, 1.2, 7.4, 7.5, 10.6, 11.2, 11.3, 11.4, 11.7, 11.8_

## Notes

- 2.4、6.4、8.6 均为必做验证任务；没有对应断言覆盖时不得勾选阶段 checkpoint
- 只有能通过启动 Neovim、打开代表性文件并执行编辑器内操作直接观察结果的任务才需要人工验收；其他任务以自动检查为完成门禁
- 相关行为任务可复用阶段套件；验收依赖未完成前暂不生成或执行对应套件
- R11.1（改造前 git 可恢复）与 R11.5（依赖需明确告知用户）非编码任务：先完成 0.2 基线提交，之后每阶段单独提交；外部依赖缺失时在阶段汇报中明确告知
- 有意的行为变化需在实施时告知用户：
  - 浮窗边框统一为 `rounded`，且 `winborder` 为全局选项，会影响 telescope / neo-tree / hop 等未显式传 `border` 的浮窗；字符对齐必须在用户日常 Windows Terminal profile 中验收
  - 自定义 filetype `fx` 改名为 `hlsl`；`.vsh` 归属 glsl（原被 fx 覆盖）；`.shader` 归 hlsl 而非内置的 `gdshader`
  - 新增命令行补全（任务 8.7），输入 `:` 与 `/` 时会出现补全弹窗
  - mason 改懒加载后新机器需手动 `:Mason` 安装 server；lua_ls、pyright、rust_analyzer 均由 Mason 管理
  - Copilot 相关插件、配置、补全 source、命令缩写、lockfile 条目与测试场景全部移除；本地插件缓存不主动删除
- 阶段 ⑥（懒加载）改动面最大，放在最后，便于独立回退

## 执行顺序

以本文从 0 到 11 的顺序和各阶段 checkpoint 为准。不得绕过 0.2 的提交基线或 1.x 的验证基线直接实施后续改动；4.1、7.1 未通过时不得进入下一阶段，最终 checkpoint 同样采用硬门禁。阶段内部只有在不存在文件冲突和行为依赖时才可并行。
