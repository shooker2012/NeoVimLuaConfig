# 1. 采用 nvim-treesitter 的 main 分支

日期：2026-02-17

## 状态

已接受

## 背景

`nvim-treesitter` 上游存在两个长期分支：

- `master` —— 旧架构，已冻结，仅接受向后兼容性修复
- `main` —— 重写版，parser 安装、高亮启动、折叠的 API 全部不同；上游 README 明示「等被认为稳定后才会支持最新 release」，缩进功能仍标记 experimental

本仓库的 `lazy-lock.json` 已经锁在 `main`（commit `2b50ab5`），但配置代码写的是 `master` 时代的 API（`ensure_installed`、`highlight`、`auto_install`、`matchup`、`nvim_treesitter#foldexpr`）。这些字段在 `main` 上不被读取，导致 parser 一个都没装上、语法高亮完全失效、折叠报 `E117`。

也就是说，仓库当时处于「插件在 main、配置在 master」的不一致状态，treesitter 整体不工作。

## 决策

迁移配置到 `main` 分支的 API，并在插件声明中**显式**写出 `branch = "main"`。

不 pin 具体 commit，版本由 `lazy-lock.json` 锁定，仅在执行 `:Lazy update` 时前进。

## 备选方案

**回退到 `master`** —— 短期最稳，配置改动最小（只需把 lock 文件切回 master）。放弃的原因是 `master` 已冻结，且 `main` 是上游进入 Neovim 核心的方向，回退等于把同样的迁移工作推到未来，届时积累的差异更大。

**pin 到当前 commit** —— 最稳定，但拿不到 parser 安装逻辑的 bug 修复，且 `:Lazy update` 会静默跳过它，容易在很久之后才发现已经落后很多个版本。

## 结果

**正面**

- treesitter 的 parser 安装、高亮、折叠恢复工作
- 与上游演进方向一致，未来 Neovim 内置 treesitter 能力增强时不需要再次迁移
- `branch = "main"` 显式声明使这个选择在代码中可见，不再依赖上游默认分支的隐式行为

**负面**

- 需要接受 `main` 稳定前可能的 API 变动；`:Lazy update` 后若 treesitter 相关配置报错，应首先怀疑上游 breaking change
- 缩进功能（`indents.scm`）仍为 experimental，本次不启用

**中性**

- parser 编译从 zig 改为 tree-sitter CLI，新增一个外部依赖（`npm install -g tree-sitter-cli`，最低版本 0.26.1）
