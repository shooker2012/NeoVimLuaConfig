# Neovim 安装步骤

## 1. 安装 Neovim

从 [Neovim Releases](https://github.com/neovim/neovim/releases/latest/download/nvim-win64.msi) 安装 Windows 版本。

## 2. 安装配置

将配置克隆到 `%LOCALAPPDATA%/nvim`：

```powershell
git clone https://github.com/shooker2012/NeoVimLuaConfig.git $env:LOCALAPPDATA\nvim
```

## 3. 安装运行依赖

### Python 3 与 pynvim

安装 [Python 3](https://www.python.org/downloads/)，将其可执行文件目录加入 `PATH`，然后安装 Neovim Python provider：

```powershell
pip install pynvim
```

### Node.js 与 tree-sitter CLI

安装 [Node.js](https://nodejs.org/en/download/)，再安装 nvim-treesitter `main` 分支用于生成和编译 parser 的 CLI：

```powershell
npm install -g tree-sitter-cli
```

parser 不再使用 Zig 编译。请确保 `tree-sitter --version` 可以在启动 Neovim 的同一环境中运行。

### ripgrep

Telescope 文本搜索依赖 [ripgrep](https://github.com/BurntSushi/ripgrep/releases)。Windows 可安装 `pc-windows-msvc.zip` 版本，并将 `rg.exe` 所在目录加入 `PATH`。

## 4. 安装 LSP server

`lua_ls`、`pyright` 和 `rust_analyzer` 统一由 Mason 管理。Mason 已改为按命令懒加载，因此新机器首次使用前需要在 Neovim 中执行：

```vim
:Mason
```

然后安装 `lua-language-server`、`pyright` 和 `rust-analyzer`。也可以直接执行：

```vim
:MasonInstall lua-language-server pyright rust-analyzer
```

配置会在启动时优先使用 Mason 的 `bin` 目录；不会隐式改用系统 PATH 或 rustup 中的同名 server。

## 5. 可选 formatter

`:Format` 由 conform.nvim 提供，但下列 formatter 是独立的系统可执行文件，配置不会自动安装：

- C/C++：`clang-format`
- Lua：`stylua`
- Python：优先 `ruff`，后备 `black`
- Rust：通过 `rust_analyzer` 调用 `rustfmt`

可按需安装，例如：

```powershell
pip install ruff black
cargo install stylua
```

`clang-format` 可随 LLVM 安装。安装后请确认对应命令位于 `PATH`；缺失时 `:Format` 会显示可读提示，不会自动下载工具。
