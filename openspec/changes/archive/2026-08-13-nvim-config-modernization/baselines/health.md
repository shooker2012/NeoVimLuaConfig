# Health 基线摘要

记录日期：2026-08-12

本摘要用于比较稳定的错误类别与弃用签名，不保存易波动的完整 `:checkhealth` 输出。

## 改造前签名

- ERROR：`nvim-treesitter` 的 `site/ is not in runtimepath`
- deprecated：`vim.tbl_add_reverse_lookup`
- deprecated：`vim.tbl_flatten`
- Copilot：离线或 client 退出相关消息；Copilot 移除后应消失
- 其他与本次变更无关的 WARNING：允许继续存在，但 checkpoint 必须报告

## 验收规则

- 最终状态不得新增 ERROR 或 deprecated 签名。
- 目标问题修复后，对应旧签名必须消失。
- 既有无关 WARNING 不阻断，但不得被静默忽略。
- 比较采用归一化后的摘要签名，不依赖时间戳、路径或输出顺序。

