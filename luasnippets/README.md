# LuaSnip 片段

Lua 片段按用途放在 `lua/` 目录中：

- `general.lua`：通用控制流、文本辅助和 `enum`。
- `logging.lua`：日志及正则触发片段。
- `azure.lua`：Azure 项目的 Lplus、模块和 UI 片段。

新增普通片段时，把它加入最接近的分类文件：

```lua
parse("trigger", [[expanded $1 text$0]]),
```

需要新的大类时，可以直接在 `lua/` 中新建 `.lua` 文件并返回片段列表；LuaSnip 会自动把该目录下的文件作为 Lua filetype 片段加载。

共享逻辑放在 `lua/Snippets/`，并通过 `ls_tracked_dopackage()` 引入，以保留 LuaSnip 的依赖文件重载能力。
