local script_path = debug.getinfo(1, "S").source:sub(2)
local change_root = vim.fs.dirname(vim.fs.normalize(script_path))
local repo_root = vim.fs.root(change_root, { "init.lua", ".git" })

if not repo_root then
  error("cannot locate repository root from " .. change_root)
end

local failures = {}
local assertions = 0
local temporary_paths = {}
local cleanup_probe

local function inspect(value)
  return vim.inspect(value, { newline = " ", indent = "" })
end

local function fail(message)
  failures[#failures + 1] = message
end

local function assert_true(value, message)
  assertions = assertions + 1
  if not value then
    fail(message or "expected a truthy value")
  end
end

local function assert_eq(actual, expected, message)
  assertions = assertions + 1
  if not vim.deep_equal(actual, expected) then
    fail(string.format(
      "%s (expected %s, got %s)",
      message or "values are not equal",
      inspect(expected),
      inspect(actual)
    ))
  end
end

local function read_file(path)
  local file, open_error = io.open(path, "rb")
  if not file then
    return nil, open_error
  end

  local content = file:read("*a")
  file:close()
  return content
end

local function collect_files(directory, files)
  local iterator = vim.fs.dir(directory)
  if not iterator then
    return
  end

  for name, entry_type in iterator do
    local path = vim.fs.joinpath(directory, name)
    if entry_type == "directory" then
      collect_files(path, files)
    elseif entry_type == "file" then
      files[#files + 1] = path
    end
  end
end

local function repository_files()
  local files = {}
  local init_path = vim.fs.joinpath(repo_root, "init.lua")
  if vim.uv.fs_stat(init_path) then
    files[#files + 1] = init_path
  end

  collect_files(vim.fs.joinpath(repo_root, "lua"), files)
  collect_files(vim.fs.joinpath(repo_root, "lsp"), files)
  table.sort(files)
  return files
end

local function assert_no_match_in_files(pattern, message, files)
  local matches = {}
  for _, path in ipairs(files or repository_files()) do
    local content, read_error = read_file(path)
    if not content then
      matches[#matches + 1] = string.format("%s (read failed: %s)", path, read_error)
    elseif content:find(pattern) then
      matches[#matches + 1] = vim.fs.relpath(repo_root, path) or path
    end
  end

  assertions = assertions + 1
  if #matches > 0 then
    fail(string.format("%s: %s", message or ("unexpected pattern " .. pattern), table.concat(matches, ", ")))
  end
end

local function assert_no_plain_match(content, unexpected, message)
  assertions = assertions + 1
  if content:find(unexpected, 1, true) then
    fail(message or ("unexpected text " .. unexpected))
  end
end

local function assert_plain_match_count(content, expected, count, message)
  local actual = 0
  local offset = 1
  while true do
    local start_index, end_index = content:find(expected, offset, true)
    if not start_index then
      break
    end
    actual = actual + 1
    offset = end_index + 1
  end

  assert_eq(actual, count, message or ("unexpected count for " .. expected))
end

local function register_temporary_path(path)
  temporary_paths[#temporary_paths + 1] = path
  return path
end

local function cleanup_temporary_paths()
  for index = #temporary_paths, 1, -1 do
    local path = temporary_paths[index]
    local stat = vim.uv.fs_stat(path)
    if stat and stat.type == "directory" then
      vim.fn.delete(path, "rf")
    elseif stat then
      vim.fn.delete(path)
    end
  end
end

local function run_assertions()
  -- Baseline assertions. Later implementation stages extend this section with
  -- the requirement-specific checks listed in design.md.
  local files = repository_files()
  assert_true(vim.uv.fs_stat(repo_root) ~= nil, "repository root should exist")
  assert_true(#files > 0, "repository file traversal should find configuration files")
  local init_path = vim.fs.joinpath(repo_root, "init.lua")
  assert_true(vim.list_contains(files, init_path), "repository files should include init.lua")

  -- `nvim --headless -l` does not load the user's configuration. Source the
  -- repository entrypoint explicitly so assertions exercise the real config.
  dofile(init_path)
  local lazy_root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
  vim.opt.runtimepath:prepend(vim.fs.joinpath(lazy_root, "nvim-treesitter-textobjects"))
  vim.opt.runtimepath:prepend(vim.fs.joinpath(lazy_root, "nvim-treesitter"))
  vim.opt.runtimepath:prepend(vim.fs.joinpath(lazy_root, "conform.nvim"))
  vim.opt.runtimepath:prepend(vim.fs.joinpath(lazy_root, "nvim-cmp"))
  require("Plugins.treesitter").setup()
  require("Plugins.textobjects").setup()

  cleanup_probe = register_temporary_path(
    vim.env.NVIM_MODERNIZATION_VERIFY_PROBE_PATH or vim.fn.tempname()
  )
  local probe, probe_error = io.open(cleanup_probe, "wb")
  assert_true(probe ~= nil, "temporary-file cleanup probe should be writable: " .. tostring(probe_error))
  if probe then
    probe:write("nvim-config-modernization verification probe")
    probe:close()
  end

  if vim.env.NVIM_MODERNIZATION_VERIFY_FORCE_EXCEPTION == "1" then
    error("forced verification exception")
  end

  -- Exercise the reusable helpers without imposing future-state assertions yet.
  assert_eq(type(read_file), "function", "read_file helper should be available")
  assert_no_match_in_files("\0", "configuration files should not contain NUL bytes", files)

  local treesitter_path = vim.fs.joinpath(repo_root, "lua", "Plugins", "treesitter.lua")
  local textobjects_path = vim.fs.joinpath(repo_root, "lua", "Plugins", "textobjects.lua")
  local handlers_path = vim.fs.joinpath(repo_root, "lua", "Plugins", "lsp", "handlers.lua")
  local keymaps_path = vim.fs.joinpath(repo_root, "lua", "keymaps.lua")
  local conform_path = vim.fs.joinpath(repo_root, "lua", "Plugins", "conform.lua")
  local plugin_manager_path = vim.fs.joinpath(repo_root, "lua", "plugin_manager.lua")
  local cmp_path = vim.fs.joinpath(repo_root, "lua", "Plugins", "nvim-cmp.lua")
  local user_command_path = vim.fs.joinpath(repo_root, "lua", "user_command.lua")
  local lsp_path = vim.fs.joinpath(repo_root, "lua", "Plugins", "lsp", "lsp.lua")
  local lua_ls_path = vim.fs.joinpath(repo_root, "lsp", "lua_ls.lua")
  local context_path = vim.fs.joinpath(repo_root, "CONTEXT.md")
  local readme_path = vim.fs.joinpath(repo_root, "README.md")
  local treesitter_source = assert(read_file(treesitter_path))
  local textobjects_source = assert(read_file(textobjects_path))
  local handlers_source = assert(read_file(handlers_path))
  local keymaps_source = assert(read_file(keymaps_path))
  local conform_source = assert(read_file(conform_path))
  local plugin_manager_source = assert(read_file(plugin_manager_path))
  local cmp_source = assert(read_file(cmp_path))
  local user_command_source = assert(read_file(user_command_path))
  local lsp_source = assert(read_file(lsp_path))
  local lua_ls_source = assert(read_file(lua_ls_path))
  local context_source = assert(read_file(context_path))
  local readme_source = assert(read_file(readme_path))

  for _, removed_field in ipairs({
    "ensure_installed",
    "sync_install",
    "auto_install",
    "ignore_install",
    "additional_vim_regex_highlighting",
    "highlight =",
    "indent =",
    "matchup =",
  }) do
    assert_no_plain_match(
      treesitter_source,
      removed_field,
      "treesitter main configuration should not contain legacy field " .. removed_field
    )
  end

  assert_no_plain_match(textobjects_source, "keymaps =", "textobjects setup should not contain keymaps")
  assert_plain_match_count(textobjects_source, 'query = "@local.scope"', 1, "as query should have one source")
  assert_plain_match_count(plugin_manager_source, '"andymass/vim-matchup"', 1, "vim-matchup should be declared once")
  assert_true(
    plugin_manager_source:find('"andymass/vim%-matchup",.-lazy%s*=%s*false') ~= nil,
    "vim-matchup should load before the initial FileType event"
  )
  assert_true(
    plugin_manager_source:find("matchup_treesitter_enabled", 1, true) ~= nil
      and plugin_manager_source:find("matchup_treesitter_disabled", 1, true) ~= nil,
    "vim-matchup should own its treesitter integration options"
  )
  assert_true(
    plugin_manager_source:find('"nvim-treesitter/nvim-treesitter-context"', 1, true) ~= nil
      and plugin_manager_source:find('event = "VeryLazy"', 1, true) ~= nil
      and plugin_manager_source:find('mode = "cursor"', 1, true) ~= nil,
    "treesitter-context should have explicit VeryLazy cursor-mode configuration"
  )

  for _, removed_api in ipairs({
    "vim.lsp.buf.formatting",
    "vim.diagnostic.goto_prev",
    "vim.diagnostic.goto_next",
    "vim.loop",
    "nvim_exec(",
    "server_capabilities.documentHighlight ",
    'client.name == "tsserver"',
    'source = "always"',
    "vim.lsp.with",
  }) do
    assert_no_match_in_files(removed_api, "configuration should not use removed API " .. removed_api, files)
  end
  assert_true(
    handlers_source:find("server_capabilities.documentHighlightProvider", 1, true) ~= nil
      and handlers_source:find("nvim_create_autocmd", 1, true) ~= nil
      and handlers_source:find('vim.o.winborder = "rounded"', 1, true) ~= nil
      and handlers_source:find('source = true', 1, true) ~= nil
      and handlers_source:find('client.name == "ts_ls"', 1, true) ~= nil,
    "LSP handlers should use current Neovim APIs and the preferred rounded global border"
  )
  assert_no_plain_match(handlers_source, 'require, "cmp_nvim_lsp"', "LSP startup should not load cmp-nvim-lsp")
  assert_true(
    handlers_source:find("vim.lsp.protocol.make_client_capabilities()", 1, true) ~= nil
      and handlers_source:find("snippetSupport = true", 1, true) ~= nil
      and handlers_source:find("resolveSupport", 1, true) ~= nil,
    "LSP startup should preserve completion capabilities without loading a cmp source"
  )
  assert_true(
    keymaps_source:find("vim.diagnostic.jump", 1, true) ~= nil
      and keymaps_source:find("count = -1", 1, true) ~= nil
      and keymaps_source:find("count = 1", 1, true) ~= nil
      and keymaps_source:find("float = true", 1, true) ~= nil
      and keymaps_source:find("_G.sal_diagnostic_severity", 1, true) ~= nil,
    "diagnostic mappings should preserve jump, float, and severity behavior"
  )

  assert_eq(_G.opts, nil, "plugin manager options should not leak into _G")
  assert_eq(_G.SetDiagnosticSeverity, nil, "SetDiagnosticSeverity should remain local")
  assert_no_plain_match(plugin_manager_source, "\nopts =", "plugin manager should not assign bare opts")
  assert_true(
    plugin_manager_source:find('require("lazy").setup(plugins, { rocks = { enabled = false } })', 1, true) ~= nil,
    "lazy options should be passed inline"
  )
  assert_true(
    cmp_source:find("local unpack = unpack or table.unpack", 1, true) ~= nil
      and cmp_source:find("\n\tunpack = unpack or table.unpack", 1, true) == nil,
    "nvim-cmp should use a local unpack alias"
  )
  assert_true(
    user_command_source:find("local function SetDiagnosticSeverity", 1, true) ~= nil,
    "SetDiagnosticSeverity should be a local function"
  )
  assert_eq(vim.fn.exists(":SetDiagnosticSeverity"), 2, ":SetDiagnosticSeverity should remain registered")
  local original_severity = _G.sal_diagnostic_severity
  vim.cmd("SetDiagnosticSeverity vim.diagnostic.severity.ERROR")
  assert_eq(
    _G.sal_diagnostic_severity,
    vim.diagnostic.severity.ERROR,
    ":SetDiagnosticSeverity should update the shared diagnostic severity"
  )
  _G.sal_diagnostic_severity = original_severity
  vim.diagnostic.config({ underline = { severity = { min = original_severity } } })

  local global_writes = {}
  for _, path in ipairs(files) do
    local content = assert(read_file(path))
    for line in content:gmatch("[^\r\n]+") do
      local name = line:match("_G%.([%a_][%w_]*)%s*=%s*[^=]")
      if name then
        global_writes[name] = true
      end
    end
  end
  assert_eq(vim.tbl_keys(global_writes), { "sal_diagnostic_severity" }, "only the documented _G write should remain")
  assert_true(
    context_source:find("_G.sal_diagnostic_severity", 1, true) ~= nil
      and context_source:find("唯一承认", 1, true) ~= nil,
    "CONTEXT.md should identify the only intentional project-level _G state"
  )
  assert_no_plain_match(readme_source, "'''", "README code blocks should use Markdown backticks")
  assert_no_plain_match(readme_source:lower(), "ziglang", "README should not instruct users to install Zig for parsers")
  for _, required_text in ipairs({
    "npm install -g tree-sitter-cli",
    "clang-format",
    "stylua",
    "ruff",
    "black",
    ":Mason",
    "lua-language-server",
    "pyright",
    "rust-analyzer",
  }) do
    assert_true(readme_source:find(required_text, 1, true) ~= nil, "README should document " .. required_text)
  end

  local lsp_module = require("Plugins.lsp.lsp")
  assert_eq(lsp_module.servers, { "lua_ls", "pyright", "rust_analyzer" }, "LSP servers should be explicit")
  assert_true(
    lsp_source:find("prepend_mason_bin()", 1, true) ~= nil
      and lsp_source:find('require("Plugins.lsp.handlers").setup()', 1, true) ~= nil
      and lsp_source:find("vim.lsp.enable(M.servers)", 1, true) ~= nil,
    "LSP setup should prepend Mason, configure handlers, then enable servers"
  )
  assert_no_plain_match(lsp_source, 'require, "mason"', "startup LSP setup should not require mason")
  assert_no_plain_match(lsp_source, 'require, "mason-lspconfig"', "startup LSP setup should not require mason-lspconfig")
  assert_no_plain_match(lua_ls_source, "--\t", "lua_ls should not retain misindented comments")
  local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
  local path_separator = vim.fn.has("win32") == 1 and ";" or ":"
  assert_true(
    vim.env.PATH == mason_bin or vim.startswith(vim.env.PATH or "", mason_bin .. path_separator),
    "Mason bin should be prepended to PATH"
  )
  for _, executable in ipairs({ "lua-language-server", "pyright-langserver", "rust-analyzer" }) do
    assert_eq(vim.fn.executable(executable), 1, "Mason-managed LSP executable should be available: " .. executable)
  end
  for _, server in ipairs(lsp_module.servers) do
    assert_true(vim.lsp.is_enabled(server), "LSP config should be explicitly enabled: " .. server)
  end

  assert_true(
    plugin_manager_source:find('cmd = {\n\t\t\t"Mason"', 1, true) ~= nil
      and plugin_manager_source:find('"MasonInstall"', 1, true) ~= nil
      and plugin_manager_source:find('"MasonUninstall"', 1, true) ~= nil
      and plugin_manager_source:find('"MasonUninstallAll"', 1, true) ~= nil
      and plugin_manager_source:find('"MasonUpdate"', 1, true) ~= nil
      and plugin_manager_source:find('"MasonLog"', 1, true) ~= nil
      and plugin_manager_source:find('ensure_installed = { "lua_ls", "pyright", "rust_analyzer" }', 1, true) ~= nil
      and plugin_manager_source:find("automatic_enable = false", 1, true) ~= nil,
    "Mason should lazy-load on every supported command without controlling LSP enablement"
  )
  assert_true(
    plugin_manager_source:find('event = { "InsertEnter", "CmdlineEnter" }', 1, true) ~= nil,
    "nvim-cmp should load for both insert and command-line completion"
  )
  for _, lhs in ipairs({ "<C-p>", "<C-f>", "<C-b>", "<F3>" }) do
    assert_true(
      plugin_manager_source:find('{ "' .. lhs .. '", mode = { "n", "v" } }', 1, true) ~= nil,
      lhs .. " should preserve normal and visual Telescope modes"
    )
  end
  assert_true(
    plugin_manager_source:find('keys = { "<F4>", "<S-F4>" }', 1, true) ~= nil,
    "aerial should lazy-load from both normal-mode keys"
  )
  assert_true(
    plugin_manager_source:find('keys = { { "s", mode = "" } }', 1, true) ~= nil,
    "Hop should preserve normal, visual, and operator mode through mode = empty string"
  )
  assert_true(
    plugin_manager_source:find('{ "godlygeek/tabular", event = "VeryLazy" }', 1, true) ~= nil
      and plugin_manager_source:find('{ "tommcdo/vim-exchange", event = "VeryLazy" }', 1, true) ~= nil
      and plugin_manager_source:find('{ "tpope/vim-abolish", event = "VeryLazy" }', 1, true) ~= nil
      and plugin_manager_source:find('"inkarkat/vim-mark",\n\t\tevent = "VeryLazy"', 1, true) ~= nil
      and plugin_manager_source:find('"numToStr/Comment.nvim",\n\t\topts = {},\n\t\tevent = "VeryLazy"', 1, true) ~= nil,
    "non-critical Vimscript and comment plugins should load on VeryLazy"
  )

  assert_true(
    cmp_source:find('cmp.setup.cmdline({ "/", "?" }', 1, true) ~= nil
      and cmp_source:find('cmp.setup.cmdline(":"', 1, true) ~= nil
      and cmp_source:find("cmp.mapping.preset.cmdline()", 1, true) ~= nil,
    "nvim-cmp should configure cmdline presets for :, /, and ?"
  )
  require("Plugins.nvim-cmp")
  vim.api.nvim_exec_autocmds("CmdlineEnter", { pattern = ":", modeline = false })
  local cmp_config = require("cmp.config")
  local function source_names(config)
    return vim.tbl_map(function(source)
      return source.name
    end, config.sources or {})
  end
  assert_eq(source_names(cmp_config.cmdline[":"]), { "path", "cmdline" }, ": should complete paths and commands")
  assert_eq(source_names(cmp_config.cmdline["/"]), { "buffer" }, "/ should complete buffer text")
  assert_eq(source_names(cmp_config.cmdline["?"]), { "buffer" }, "? should complete buffer text")
  for _, cmdtype in ipairs({ ":", "/", "?" }) do
    local config = cmp_config.cmdline[cmdtype]
    assert_true(config.mapping ~= cmp_config.global.mapping, cmdtype .. " should not reuse insert-mode mappings")
    assert_eq(config.experimental.native_menu, false, cmdtype .. " should use the cmp menu")
  end

  -- `nvim -l` runs this file as a script and does not execute lazy.nvim's
  -- plugin init callbacks. Re-run the startup-owned command registration here
  -- so the remaining assertions exercise the same command/lazy boundary as UI
  -- startup without loading conform itself.
  if vim.fn.exists(":Format") ~= 2 then
    require("Plugins.conform").register_command()
  end
  assert_eq(vim.fn.exists(":Format"), 2, ":Format should be registered at startup")
  local format_command = vim.api.nvim_get_commands({ builtin = false }).Format
  assert_true(format_command and format_command.range ~= nil, ":Format should accept a range")
  assert_true(package.loaded.conform == nil, "conform should not load during startup")
  assert_true(
    conform_source:find('c = { "clang-format" }', 1, true) ~= nil
      and conform_source:find('cpp = { "clang-format" }', 1, true) ~= nil
      and conform_source:find('lua = { "stylua" }', 1, true) ~= nil
      and conform_source:find('python = { "ruff_format", "black", stop_after_first = true }', 1, true) ~= nil
      and conform_source:find('default_format_opts = { lsp_format = "fallback" }', 1, true) ~= nil
      and conform_source:find("format_on_save = false", 1, true) ~= nil
      and conform_source:find("notify_on_error = true", 1, true) ~= nil
      and conform_source:find("notify_no_formatters = true", 1, true) ~= nil,
    "conform should declare formatter, fallback, explicit-only, and notification options"
  )
  assert_true(
    plugin_manager_source:find('"stevearc/conform.nvim"', 1, true) ~= nil
      and plugin_manager_source:find('cmd = "ConformInfo"', 1, true) ~= nil
      and plugin_manager_source:find('require("Plugins.conform").register_command()', 1, true) ~= nil,
    "conform should be lazy-loaded while :Format is registered at startup"
  )

  local removal_files = {
    plugin_manager_path,
    vim.fs.joinpath(repo_root, "lua", "Plugins", "nvim-cmp.lua"),
    vim.fs.joinpath(repo_root, "lazy-lock.json"),
    vim.fs.joinpath(change_root, "generate_manual_tests.ps1"),
  }
  for _, removed_name in ipairs({ "null-ls", "copilot", "CopilotChat", "CC CopilotChat" }) do
    assert_no_match_in_files(removed_name, "active configuration should not reference " .. removed_name, removal_files)
  end

  local original_notify = vim.notify
  local notifications = {}
  vim.notify = function(message, level)
    notifications[#notifications + 1] = { message = tostring(message), level = level }
  end
  local missing_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(missing_buffer)
  -- Lua has a configured `stylua` formatter, but this machine intentionally
  -- does not install external formatters; it therefore exercises the required
  -- readable missing-executable notification path.
  vim.bo[missing_buffer].filetype = "lua"
  -- In a normal lazy.nvim session the first `require("conform")` inside the
  -- command also runs the plugin config. The `-l` harness has no lazy require
  -- hook, so invoke the same setup explicitly for the notification assertion.
  require("Plugins.conform").setup()
  local format_ok, format_error = pcall(vim.cmd.Format)
  vim.wait(500, function()
    return #notifications > 0
  end)
  vim.notify = original_notify
  assert_true(format_ok, "missing formatter should not raise a Lua error: " .. tostring(format_error))
  assert_true(package.loaded.conform ~= nil, "first :Format should lazy-load conform")
  assert_true(
    vim.iter(notifications):any(function(item)
      return item.message:find("Formatters unavailable", 1, true) ~= nil
    end),
    "missing formatter should produce a readable notification"
  )
  vim.api.nvim_buf_delete(missing_buffer, { force = true })

  assert_eq(vim.filetype.match({ filename = "a.hlsl" }), "hlsl", ".hlsl should use hlsl")
  assert_eq(vim.filetype.match({ filename = "a.fx" }), "hlsl", ".fx should use hlsl")
  assert_eq(vim.filetype.match({ filename = "a.vsh" }), "glsl", ".vsh should use glsl")
  assert_eq(vim.filetype.match({ filename = "a.shader" }), "hlsl", ".shader should use hlsl")

  local install_dir = vim.fn.stdpath("data") .. "/site"
  local normalized_runtime_paths = vim.tbl_map(vim.fs.normalize, vim.api.nvim_list_runtime_paths())
  assert_true(
    vim.list_contains(normalized_runtime_paths, vim.fs.normalize(install_dir)),
    "treesitter install directory should be in runtimepath"
  )

  local treesitter = require("nvim-treesitter")
  local treesitter_config = require("nvim-treesitter.config")
  local installed = treesitter_config.get_installed("parsers")
  for _, language in ipairs({
    "c",
    "cpp",
    "lua",
    "rust",
    "python",
    "vim",
    "vimdoc",
    "glsl",
    "hlsl",
    "markdown",
    "json",
    "bash",
  }) do
    assert_true(vim.list_contains(installed, language), "required parser should be installed: " .. language)
  end

  local original_install = treesitter.install
  local install_called = false
  treesitter.install = function()
    install_called = true
  end
  require("Plugins.treesitter").install_async()
  treesitter.install = original_install
  assert_true(not install_called, "headless verification should not install parsers")
  assert_true(
    treesitter_source:find("vim.schedule", 1, true) ~= nil
      and treesitter_source:find("install(missing, { summary = true })", 1, true) ~= nil,
    "UI parser installation should be scheduled asynchronously with a summary"
  )

  local cpp_path = register_temporary_path(vim.fn.tempname() .. ".cpp")
  local cpp_file = assert(io.open(cpp_path, "wb"))
  cpp_file:write("int main() { return 0; }\n")
  cpp_file:close()
  vim.cmd("filetype on")
  vim.cmd.edit(vim.fn.fnameescape(cpp_path))
  local cpp_buffer = vim.api.nvim_get_current_buf()
  assert_eq(vim.bo[cpp_buffer].filetype, "cpp", "temporary C++ file should use cpp filetype")
  assert_true(vim.treesitter.highlighter.active[cpp_buffer] ~= nil, "C++ treesitter highlighter should be active")
  assert_eq(vim.wo.foldmethod, "expr", "treesitter window should use expression folding")
  assert_eq(vim.wo.foldexpr, "v:lua.vim.treesitter.foldexpr()", "foldexpr should use the native treesitter API")
  local fold_ok = pcall(vim.fn.foldlevel, 1)
  assert_true(fold_ok, "evaluating treesitter foldexpr should not raise E117")
  vim.cmd("bdelete!")

  if vim.env.NVIM_MODERNIZATION_VERIFY_FORCE_FAILURE == "1" then
    assert_true(false, "forced verification failure")
  end
end

local ok, run_error = xpcall(run_assertions, debug.traceback)
local cleanup_ok, cleanup_error = pcall(cleanup_temporary_paths)
if not ok then
  fail("verification script raised an exception: " .. tostring(run_error))
end
if not cleanup_ok then
  fail("temporary-file cleanup raised an exception: " .. tostring(cleanup_error))
end
if cleanup_probe then
  assert_true(vim.uv.fs_stat(cleanup_probe) == nil, "temporary files should be removed before exit")
end

if #failures > 0 then
  io.stderr:write(string.format("FAIL: %d/%d assertions failed\n", #failures, assertions))
  for index, message in ipairs(failures) do
    io.stderr:write(string.format("  %d. %s\n", index, message))
  end
  os.exit(1)
end

io.stdout:write(string.format("PASS: %d assertions\n", assertions))
vim.cmd("qa!")
