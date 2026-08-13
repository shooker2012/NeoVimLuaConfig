# 2. LSP server 可执行文件统一由 Mason 管理

日期：2026-08-12

## 状态

已接受

## 背景

配置启用 `lua_ls`、`pyright` 与 `rust_analyzer`。Windows 上这些 server 都是 Neovim 之外的独立可执行程序；系统 PATH、语言工具链和 Mason 可能同时提供同名命令，导致不同机器实际启动不同版本。

Mason 改为命令触发的懒加载后，`mason.setup()` 不再在启动期自动修改 PATH，但原生 `vim.lsp.enable()` 仍需在打开文件时找到 server。

## 决策

三个 LSP server 的可执行文件均由 Mason 管理。LSP 启用前，将 `stdpath("data") .. "/mason/bin"` 前置到 PATH；即使系统 PATH 或 rustup 已提供同名命令，也不作为 fallback。

Mason 插件本身保持懒加载，但其安装目录中的 server 可执行文件必须从正常启动路径可见。新机器由用户通过 `:Mason` 安装缺失 server。

## 备选方案

**各语言使用各自工具链**：Rust 使用 rustup，Python 与 Lua 使用系统包管理器。与语言生态更贴近，但安装来源和版本更新方式分散，不利于复现这套编辑器配置。

**Mason 优先、系统 PATH fallback**：缺包时更容易启动，但实际二进制来源会随机器状态静默变化，难以诊断。

## 结果

**正面**

- 三个 server 的安装位置、更新入口和诊断方式一致
- 配置在不同 Windows 机器上的行为更可复现
- Mason 插件逻辑无需加入启动热路径

**负面**

- 已通过 rustup 或系统包管理器安装的同名 server 不会被本配置复用
- Mason 安装缺失时，对应 LSP 不会启动，需要用户显式安装

