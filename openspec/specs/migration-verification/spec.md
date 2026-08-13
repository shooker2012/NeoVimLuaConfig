# Migration Verification Specification

## Purpose

规定配置迁移的安全边界、自动验证、人工验收与结果归档方式。

## Requirements

### Requirement: R11 改造过程的安全性与可验证性
系统 SHALL 实现“改造过程的安全性与可验证性”。作为使用者，我希望改造过程可控、可回滚，并且每一步都经过验证。

#### Scenario: R11.1 验收条件
- **WHEN** 开始改造前
- **THEN** Kiro→OpenSpec 迁移、验证资产、`.gitignore` 与 `lazy-lock.json` 策略 SHALL 先形成可恢复的迁移基线提交，后续每个阶段 SHALL 独立提交

#### Scenario: R11.2 验收条件
- **WHEN** 每个阶段完成
- **THEN** 该阶段的改动 SHALL 通过启动无错误验证

#### Scenario: R11.3 验收条件
- **WHEN** 全部改造完成
- **THEN** `:checkhealth` 与迁移基线的稳定问题签名相比 SHALL 不新增 ERROR 或 deprecated；既有且与本任务无关的 WARNING MAY 保留但必须报告

#### Scenario: R11.4 验收条件
- **WHEN** 验证过程创建了临时文件
- **THEN** 这些文件 SHALL 在验证成功、断言失败或脚本异常时都被清理

#### Scenario: R11.5 验收条件
- **WHEN** 某项改动需要用户在系统层面安装依赖
- **THEN** 该依赖 SHALL 被明确告知用户而非静默失败

#### Scenario: R11.6 可观察行为人工验收包
- **WHEN** 某项任务的结果能通过启动 Neovim、打开代表性文件并进行编辑器内操作直接观察
- **THEN** 系统 SHALL 生成包含 `TESTING.md` 与代表性文件的人工验收包，供用户亲自验证实际效果
- **AND** 纯规格、Git 基线、验证脚本、静态断言、内部状态、性能报告或文档任务 SHALL 只接受自动检查，不要求人工验收

#### Scenario: R11.7 可观察行为验收结果
- **WHEN** 用户完成测试文件的人工验证
- **THEN** 可再生测试夹具 SHALL 被清理或忽略，对应 checkpoint SHALL 只提交包含环境、通过项、失败项和未验证项的结果摘要

#### Scenario: R11.8 checkpoint 硬门禁
- **WHEN** 阶段 checkpoint 准备关闭
- **THEN** 自动化断言、启动、目标功能与既有行为回归 SHALL 全部通过；真实失败 SHALL 阻塞后续阶段，仅明确由外部工具或服务不可用导致的项目 MAY 记录为“未验证”后继续

#### Scenario: R11.9 夹具严格幂等
- **WHEN** 同一人工验证套件被重复生成或模板删除了旧夹具
- **THEN** 生成器 SHALL 重建该套件专用目录并删除陈旧文件，使输出状态与当前模板完全一致

#### Scenario: R11.10 按可观察性完成任务
- **WHEN** 顶层编号任务的实现和自动化检查已经完成
- **THEN** 具有可直接观察的 Neovim 行为的任务 SHALL 仅在用户按对应 `TESTING.md` 明确确认通过后勾选完成
- **AND** 不具有可直接观察的 Neovim 行为的任务 SHALL 在自动检查通过后勾选完成，不得为了形式要求用户审阅内部实现、命令输出或文档

#### Scenario: R11.11 可观察行为验收依赖
- **WHEN** 某项可观察行为的人工验收依赖其他尚未完成的任务
- **THEN** 当前任务 SHALL 等待依赖完成后再生成或执行验收；测试文件 MAY 在相关任务间复用

#### Scenario: R11.12 人工验收结果归档
- **WHEN** 用户完成某项可观察行为的人工验收
- **THEN** 系统 SHALL 将环境、操作项、通过项、失败项、备注与确认日期保存到 `verification/<任务编号>.md` 并纳入版本控制，生成的测试文件与临时 `TESTING.md` SHALL 保持忽略且可清理
