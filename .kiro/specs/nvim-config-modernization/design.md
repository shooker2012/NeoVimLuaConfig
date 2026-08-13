> **只读历史文档**：本任务已迁移到 `openspec/changes/nvim-config-modernization/`，后者是当前唯一实施与验收依据。

# Design Document

## Overview

本设计将 Neovim 配置从「treesitter master 时代 + 一批废弃 API」迁移到「treesitter main 分支 + Neovim 0.11 原生 LSP + 懒加载」的状态。

设计遵循三条原则：

1. **先恢复功能，再做优化** —— treesitter 失效是唯一影响日常使用的问题，优先级最高
2. **行为等价** —— 除被迫迁移的废弃 API，所有按键与命令的语义保持不变
3. **失败可见但不阻塞** —— 外部依赖（tree-sitter CLI、clang-format）缺失时给出可读提示，不抛堆栈、不阻塞启动

### 已验证的技术前提

| 结论 | 验证方式 |
| --- | --- |
| `install()` 幂等，已安装则跳过 | `install.lua:477` `if not force and vim.list_contains(config.get_installed(), lang)` |
| `install()` 是 async，不阻塞 | `M.install = a.async(function(languages, options)` |
| `InstallOptions` 支持 `force` / `generate` / `max_jobs` / `summary` | `install.lua:500-504` |
| hlsl parser 存在，依赖 cpp；glsl 依赖 c | `parsers.lua` 中 `requires = { 'cpp' }` / `{ 'c' }` |
| `requires` 会被自动加入安装列表 | `config.norm_languages` 内 `parsers[lang].requires` 展开 |
| `vim.lsp.enable` / `vim.o.winborder` / `vim.treesitter.language.register` / `vim.treesitter.foldexpr` 均可用 | `nvim --clean` 实测 |
| main 分支用 `tree-sitter` CLI 编译，不再用 zig | `install.lua:204,307` 调用 `tree-sitter generate/build` |
| mason 现有包：lua-language-server、pyright（**无 rust_analyzer**） | `nvim-data/mason/packages` 目录 |

---

## Architecture

### 目标文件结构

```
nvim/
├── init.lua                      改：vim.uv、winborder、filetype 规则移交 vim.filetype.add
├── lsp/
│   ├── lua_ls.lua                改：清理错乱注释
│   ├── pyright.lua               新增（可选，占位保持一致性）
│   └── rust_analyzer.lua         新增（可选）
├── lua/
│   ├── keymaps.lua               改：diagnostic.jump
│   ├── user_command.lua          改：SetDiagnosticSeverity 去全局化
│   ├── plugin_manager.lua        改：vim.uv、去 null-ls、加 conform、懒加载、去 _G.opts
│   └── Plugins/
│       ├── treesitter.lua        重写：install + FileType autocmd
│       ├── textobjects.lua       新增：从 treesitter.lua 拆出
│       ├── conform.lua           新增
│       ├── nvim-cmp.lua          改：local unpack
│       ├── telescope.lua         不变（仅由 lazy keys 触发）
│       ├── neo-tree.lua          不变
│       └── lsp/
│           ├── lsp.lua           改：显式 vim.lsp.enable，不依赖 mason 自动启用
│           ├── handlers.lua      改：winborder、documentHighlightProvider、autocmd API
│           └── utility.lua       不变
└── README.md                     改：tree-sitter CLI、格式化工具、移除 zig 说明
```

### 加载时序

```mermaid
flowchart TD
    A[init.lua] --> B[基础 vim.opt]
    B --> C[vim.filetype.add 注册 glsl/hlsl]
    C --> D[require keymaps]
    D --> E[require user_command]
    E --> F[require plugin_manager]
    F --> G[lazy.setup]
    G --> H[启动期插件<br/>colorscheme / lualine / treesitter]
    G --> I[懒加载插件<br/>mason / telescope / aerial / conform / CopilotChat]
    F --> J[require Plugins.lsp.lsp]
    J --> K[handlers.setup:<br/>diagnostic + vim.lsp.config'*']
    K --> L[vim.lsp.enable 显式启用 server]
    H --> M[FileType autocmd 注册]
    M --> N[打开文件时:<br/>treesitter.start + foldexpr]
```

关键顺序约束：`vim.lsp.config("*", ...)` 必须在 `vim.lsp.enable(...)` 之前执行，否则 `on_attach` 与 `capabilities` 不会应用到已启用的 server。

---

## Components and Interfaces

### 1. treesitter 模块（`Plugins/treesitter.lua`）

**职责**：声明 parser 列表、触发安装、在 FileType 事件启动高亮与折叠。

```lua
local M = {}

-- Parsers to install. Dependencies (c for glsl, cpp for hlsl) are resolved
-- automatically by norm_languages.
M.languages = {
    "c", "cpp", "lua", "rust", "python",
    "vim", "vimdoc", "query",
    "glsl", "hlsl",
    "markdown", "markdown_inline", "json", "bash",
}

function M.setup()
    local ok, ts = pcall(require, "nvim-treesitter")
    if not ok then return end

    ts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })

    -- The `fx` filetype (set by init.lua for .hlsl/.fx/.shader) has no parser
    -- of its own; map it onto the hlsl parser.
    vim.treesitter.language.register("hlsl", { "fx" })

    M.install_async()
    M.attach_autocmd()
end
```

**安装策略**

`install()` 幂等且异步，但仍不在启动路径上直接调用 —— 首次运行会拉取十几个 grammar 仓库，即使异步也会争抢 IO。设计为：

```lua
function M.install_async()
    if vim.fn.executable("tree-sitter") == 0 then
        vim.schedule(function()
            vim.notify(
                "tree-sitter CLI not found; parsers cannot be installed.\n"
                    .. "Install with: npm install -g tree-sitter-cli",
                vim.log.levels.WARN
            )
        end)
        return
    end

    local config = require("nvim-treesitter.config")
    local missing = vim.tbl_filter(function(lang)
        return not vim.list_contains(config.get_installed("parsers"), lang)
    end, M.languages)

    if #missing == 0 then return end

    vim.schedule(function()
        require("nvim-treesitter").install(missing, { summary = true })
    end)
end
```

设计要点：
- CLI 缺失时只 notify，不报错、不阻塞（R1.5）
- 自己先过滤 missing，避免无谓地进入 async 调度（R1.6）
- `vim.schedule` 把安装推到启动之后
- `summary = true` 让用户看到进度而非静默

**高亮与折叠挂载**

```lua
-- Filetypes that map to an available parser. `fx` is registered to hlsl above.
M.filetypes = {
    "c", "cpp", "lua", "rust", "python",
    "vim", "help", "query",
    "glsl", "fx",
    "markdown", "json", "sh", "bash",
}

function M.attach_autocmd()
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("sal_treesitter", { clear = true }),
        pattern = M.filetypes,
        callback = function(args)
            local lang = vim.treesitter.language.get_lang(args.match)
            if not lang or not pcall(vim.treesitter.language.add, lang) then
                return
            end

            vim.treesitter.start(args.buf, lang)
            vim.wo[0][0].foldmethod = "expr"
            vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end,
    })
end
```

设计要点：
- `pcall(vim.treesitter.language.add, lang)` 是 parser 可用性探测，失败则静默 return，回落内置 syntax（R2.3）
- `vim.wo[0][0]` 而非 `vim.o`，因为 `foldexpr` 是窗口局部选项（R3.3）；`[0][0]` 形式避免污染全局默认值
- 不设 `foldenable`，`init.lua` 里的 `foldenable = false` 继续生效（R3.4）
- 全局 `foldmethod`/`foldexpr` 从旧配置中删除

**vim-matchup 集成**

master 时代通过 treesitter 的 `matchup = { enable = true }` 启用。main 分支没有这个入口，改用 vim-matchup 自己的选项：

```lua
vim.g.matchup_matchparen_offscreen = { method = "popup" }
vim.g.matchup_treesitter_enabled = 1
vim.g.matchup_treesitter_disabled = { "c", "ruby" }
```

放在 vim-matchup 插件声明的 `init`（而非 `config`），保证在插件加载前生效。

### 2. textobjects 模块（`Plugins/textobjects.lua`）

从 treesitter.lua 拆出，消除 setup 里的死 `keymaps` 字段（R4.2）与 `as` 的重复定义（R4.3）。

```lua
local M = {}

-- Single source of truth for textobject mappings.
M.mappings = {
    { key = "af", query = "@function.outer", group = "textobjects" },
    { key = "if", query = "@function.inner", group = "textobjects" },
    { key = "ac", query = "@class.outer",    group = "textobjects" },
    { key = "ic", query = "@class.inner",    group = "textobjects" },
    { key = "as", query = "@local.scope",    group = "locals" },
}

function M.setup()
    local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
    if not ok then return end

    textobjects.setup({
        select = {
            lookahead = true,
            include_surrounding_whitespace = false,
        },
    })

    for _, m in ipairs(M.mappings) do
        vim.keymap.set({ "x", "o" }, m.key, function()
            require("nvim-treesitter-textobjects.select")
                .select_textobject(m.query, m.group)
        end, { remap = false, silent = true, desc = "Select " .. m.query })
    end
end
```

`as` 统一为 `@local.scope` + `locals`（与原手写映射一致，因为那份才是实际生效的）。

### 3. LSP 模块

**`Plugins/lsp/lsp.lua`** —— 关键变更是**不再依赖 mason-lspconfig 的 `automatic_enable`**。

理由：mason 要改成 `cmd` 懒加载（R10.2），而 `automatic_enable` 是当前 LSP 自动启动的唯一来源（前面实测 `vim.lsp._enabled_configs` 有三个 server 全靠它）。懒加载后 mason 在启动时不加载，server 就不会被启用，直接违反 R10.7。

解法是把「启用」这件事从 mason 手里收回，由配置显式声明：

```lua
local M = {}

M.servers = { "lua_ls", "pyright", "rust_analyzer" }

function M.setup()
    -- Must run before vim.lsp.enable so that on_attach/capabilities apply.
    require("Plugins.lsp.handlers").setup()

    -- Server definitions come from the native lsp/ directory.
    vim.lsp.enable(M.servers)
end

return M
```

mason 的角色退化为「按需安装 server 二进制」，通过 `cmd = { "Mason", "MasonInstall", ... }` 懒加载。`ensure_installed` 交给 mason-lspconfig，但它只在 mason 被加载时才生效 —— 这是有意的权衡：

- 收益：启动省下约 25ms
- 代价：新机器首次使用需手动 `:Mason` 装 server
- 记录在 README（R11.5）

注意 rust_analyzer 当前并未装上（mason packages 里只有 lua-language-server 和 pyright），说明 `ensure_installed` 本来就没可靠工作。这个既有问题会在 README 里说明，不在本次范围内修复。

**`Plugins/lsp/handlers.lua`** —— 五处 API 迁移。

| 项 | 现状 | 改为 |
| --- | --- | --- |
| 浮窗边框 | `vim.lsp.with()` 覆盖两个 handler | `vim.o.winborder = "rounded"` |
| document highlight 能力 | `server_capabilities.documentHighlight` | `server_capabilities.documentHighlightProvider` |
| autocmd 创建 | `nvim_exec` + vimscript augroup | `nvim_create_autocmd` |
| `:Format` | `vim.lsp.buf.formatting()` | 移交 conform（见下） |
| tsserver 判断 | `client.name == "tsserver"` | `"ts_ls"` |
| float source | `source = "always"` | `source = true` |

```lua
local function lsp_highlight_document(client, bufnr)
    if not client.server_capabilities.documentHighlightProvider then
        return
    end

    local group = vim.api.nvim_create_augroup(
        "sal_lsp_document_highlight_" .. bufnr, { clear = true })

    vim.api.nvim_create_autocmd("CursorHold", {
        group = group,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = group,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
    })
end
```

augroup 按 bufnr 命名，替代原 vimscript 里 `autocmd! * <buffer>` 的清理语义。

`winborder` 是全局选项，会同时影响 hover、signature help、diagnostic float 与补全文档窗。原配置里 hover/signature 用 `rounded`、diagnostic float 用 `double`，统一为 `rounded` 是有意的行为变化，会在实施时告知。

### 4. conform 模块（`Plugins/conform.lua`）

```lua
local M = {}

M.formatters_by_ft = {
    c = { "clang-format" },
    cpp = { "clang-format" },
    lua = { "stylua" },
    python = { "ruff_format", "black", stop_after_first = true },
    -- rust: handled by rust_analyzer's built-in rustfmt via lsp_format
}

function M.setup()
    require("conform").setup({
        formatters_by_ft = M.formatters_by_ft,
        -- Fall back to LSP when no external formatter is configured.
        default_format_opts = { lsp_format = "fallback" },
        format_on_save = false,
    })
end

return M
```

`:Format` 命令重新定义为全局命令（不再在 `on_attach` 里重复创建）：

```lua
vim.api.nvim_create_user_command("Format", function(args)
    local range
    if args.count ~= -1 then
        range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, math.huge },
        }
    end
    require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true, desc = "Format buffer or range" })
```

设计要点：
- `lsp_format = "fallback"` 满足 R6.6：有外部工具用工具，没有则走 LSP。rust 因此自动走 rust_analyzer 的 rustfmt（R6.5）
- `format_on_save = false` 保持显式调用（R6.8）
- `range = true` 支持可视区域格式化，比原 `:Format` 更强
- conform 通过 `cmd = "ConformInfo"` + 上述命令懒加载（R6.9）
- 工具缺失时 conform 自身会报「no formatter available」，可读（R6.7）；`ConformInfo` 可诊断

python 用 `ruff_format` 优先、`black` 兜底，`stop_after_first` 避免两个都跑。两者当前都未安装，属于 README 待办。

### 5. 全局变量清理

| 位置 | 问题 | 解法 |
| --- | --- | --- |
| `plugin_manager.lua` | `opts = { rocks = ... }` 漏 local | 直接内联进 `lazy.setup(plugins, { rocks = { enabled = false } })` |
| `nvim-cmp.lua` | `unpack = unpack or table.unpack` | `local unpack = unpack or table.unpack` 提到文件顶部 |
| `user_command.lua` | `function SetDiagnosticSeverity` | 改 `local function`，命令注册处引用不变 |

`SetDiagnosticSeverity` 去全局化后行为需保持：它读写 `_G.sal_diagnostic_severity`（这个全局是有意设计的跨模块状态，保留），并调用 `vim.diagnostic.config` 更新 underline severity。

### 6. filetype 规则迁移

`init.lua` 现用两条 `vim.cmd('au BufNewFile,BufRead ...')`。改为 `vim.filetype.add`，更快且可被 treesitter 的 FileType autocmd 正确捕获：

```lua
vim.filetype.add({
    extension = {
        frag = "glsl", vert = "glsl", fp = "glsl", vp = "glsl",
        glsl = "glsl", fsh = "glsl",
        hlsl = "fx", fx = "fx", fxh = "fx", psh = "fx", shader = "fx",
    },
})
```

原配置里 `vsh` 同时出现在 glsl 和 fx 两条规则中（后者覆盖前者）。`vim.filetype.add` 不允许重复键，需要决断 —— 保留 glsl（第一条规则的语义，且 `.vsh` 通常是 GLSL vertex shader）。这是行为变化，实施时告知。

---

## Startup Performance Strategy

改造前基线 327ms，热点 `plugin_manager` self 89ms、`Plugins.lsp.lsp` self 25ms。

| 插件 | 当前 | 改为 | 依据 |
| --- | --- | --- | --- |
| mason | 启动加载 | `cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonLog" }` | LSP 启用已收回自管 |
| mason-lspconfig | 启动加载 | mason 的 dependency | 同上 |
| null-ls | 启动加载 | **删除** | 从未引用 |
| telescope | 启动加载 | `keys = { "<C-p>", "<C-f>", "<C-b>", "<F3>" }` | 配置里已有这些映射 |
| aerial | 启动加载 | `keys = { "<F4>", "<S-F4>" }` | 同上 |
| CopilotChat | 启动加载 | `cmd = "CopilotChat"` | 已有 `CC` abbrev |
| conform | 新增 | `cmd = "ConformInfo"` + Format 命令内 require | 按需 |
| tabular / vim-exchange / vim-abolish / vim-mark | 启动加载 | `event = "VeryLazy"` | 非启动必需 |
| nvim-cmp 及 sources | 启动加载 | `event = "InsertEnter"` | 仅插入模式需要 |
| treesitter | 启动加载 | 保持 | 需注册 FileType autocmd |
| colorscheme / lualine | 启动加载 | 保持 | 视觉必需 |

telescope 与 aerial 用 `keys` 懒加载时，按键需在 lazy 声明里定义，而各自的 `config` 里还会再定义一次同名映射 —— lazy 的 `keys` 是占位映射，插件加载后被 config 里的真实映射覆盖，这是 lazy 的标准模式，行为一致（R10.3、R10.4、R10.6）。

**风险**：`keys` 占位映射对 `<C-p>` 这类高频键有首次触发延迟（需等插件加载）。可接受，因为只有首次。

**测量方法**：`nvim --startuptime`，连续 5 次取中位数，排除首次的文件缓存冷启动（R10.8）。若达不到 200ms，记录瓶颈（R10.9）。

---

## Error Handling

| 场景 | 处理 |
| --- | --- |
| tree-sitter CLI 缺失 | `vim.notify` WARN + 安装指引，跳过安装，不阻塞 |
| parser 未安装但打开对应文件 | `pcall(language.add)` 失败则 return，回落内置 syntax |
| parser 编译失败 | `install()` 内部 logger 记录，`summary = true` 显示 |
| clang-format / stylua 缺失 | conform 报 "no formatter available"；`:ConformInfo` 诊断 |
| 某 LSP server 二进制缺失 | `vim.lsp.enable` 不报错，server 静默不启动；`:checkhealth vim.lsp` 可见 |
| 插件 require 失败 | 各模块 setup 入口统一 `pcall` |

所有对外部可执行文件的依赖都走 `vim.fn.executable()` 预检而非 pcall 捕获异常，这样能给出可操作的提示而非堆栈。

---

## Testing Strategy

配置类项目没有单元测试框架，验证依赖可执行的断言脚本。

### 验证脚本设计

在 spec 目录下建 `verify.lua`，用 `nvim --headless -l` 执行，写结果到文件后退出。

**关键约束**（来自本次调查中的实际踩坑）：

- **不要在 headless 下等待 LSP 挂载**。`vim.wait` 等 client 时，lua_ls 在 headless 会以 exit code 1 退出，错误消息触发无人应答的 hit-enter 提示，进程永久挂起。LSP 相关断言改为检查配置状态（`vim.lsp.config`、`vim.lsp.is_enabled`）而非运行时 client。
- **命令要带 timeout**，避免挂起时无限等待。
- **临时文件用完即删**（R11.4）。

### 断言矩阵

| 需求 | 断言 |
| --- | --- |
| R1.2 | `vim.list_contains(vim.opt.rtp:get(), stdpath('data')..'/site')` |
| R1.4 | `get_installed('parsers')` 包含目标列表 |
| R1.8 | `vim.treesitter.language.get_lang('fx') == 'hlsl'` |
| R2.2 | 打开 `.cpp` 后 `vim.treesitter.highlighter.active[buf] ~= nil` |
| R3.1 | `pcall(vim.fn.eval, ...)` 不再出现 E117；`vim.wo.foldexpr` 含 `vim.treesitter.foldexpr` |
| R4.1 | grep treesitter.lua 无 `ensure_installed`/`highlight`/`matchup` 等字段 |
| R5.x | grep 全仓库无 `buf.formatting`/`goto_prev`/`goto_next`/`vim.loop`/`nvim_exec(`/`documentHighlight\b`/`tsserver` |
| R6.1 | `vim.fn.exists(':Format') == 2` 且 conform 可 require |
| R7.2 | grep 无 `null-ls` |
| R8.1-8.3 | `_G.opts == nil`、`rawget(_G,'unpack') == nil`、`_G.SetDiagnosticSeverity == nil` |
| R10.1 | `--startuptime` 5 次中位数 < 200ms |
| R11.3 | `checkhealth` 输出无新增 ERROR |

### 分阶段验证

每个实施阶段结束跑一次「启动无错误」基线检查：

```
nvim --headless -c "messages" -c "qa!" 2>&1
```

输出中不应出现 `E\d+`、`Error`、`deprecated`。

---

## Rollback Plan

配置在 git 仓库中（已确认 `git status` 可用），改造前工作区仅有一处既有的 `.gitignore` 修改。

- 每个阶段单独提交，便于 `git revert` 单点回退
- 不使用 `git commit --amend`、`reset --hard` 等破坏性操作
- 阶段边界：① treesitter 修复 ② API 迁移 ③ conform + null-ls ④ 清理 ⑤ 懒加载 ⑥ 文档
- `lazy-lock.json` 会因增删插件变化，一并提交

前三个阶段任一失败都可独立回退而不影响其他阶段，因为它们改动的文件几乎不重叠。阶段 ⑤（懒加载）改动面最大且风险最高，放在最后。
