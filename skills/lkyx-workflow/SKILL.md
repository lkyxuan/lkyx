---
name: lkyx-workflow
description: Use whenever the user describes something new to build (a product idea, feature, tool, script, crawler or automation) before writing any code. Sets the order of steps - clarify, search prior art, short plan, build, take notes - and decides which Superpowers skills to use.
---

# lkyx 开发流程（总入口）

这是 0xmiracle 的个人开发流程。它只规定**顺序**和**轻重**，具体每一步交给对应的 skill 执行。
默认走**轻量模式**：个人快速迭代，能在对话里说清楚的就不落文件。

## 什么时候用
- 用户说"我想做 / 有个想法 / 能不能做一个 X"
- 要给现有产品加一个新功能
- 不用于：修一个具体 bug（用 Superpowers 的 `systematic-debugging`）、改配置、纯问答

## 流程

### 1. 想清楚要什么（澄清）
- 小想法：在对话里用 2–3 个问题确认目标、使用场景、成功标准，复述一遍让用户确认。
- 大项目（多模块、要长期维护）：调用 Superpowers 的 `brainstorming`，产出设计文档。
- 没装 Superpowers 时：自己按上面的方式问清楚即可。

### 2. 先搜开源（必做）
调用 `prior-art-first`。拿到调研报告后**停下来等用户选**：直接用 / 改造 / 自己写。
用户明确说"跳过调研"时才可以省略。

### 3. 一页小计划
- 默认：在对话里写 5–10 行——做什么、用什么（来自第 2 步的选择）、改哪些文件、怎么验证。用户点头后开始。
- 大项目：调用 Superpowers 的 `writing-plans`，计划写进 `docs/plans/`。

### 4. 动手做
- 默认：直接实现，写到能跑并验证（跑一遍、给出结果）。
- 大项目或用户要求严谨时：用 Superpowers 的 `test-driven-development`、`subagent-driven-development` 或 `executing-plans`。
- 原型 / 一次性脚本不强制 TDD、不强制 worktree。

### 5. 做完记一笔
在项目的 `docs/notes/<YYYY-MM-DD>-<主题>.md` 写几行（没有目录就建）：

```
# <主题>
- 目标：<一句话>
- 调研结论：<选了什么，为什么；看过但没用的候选>
- 关键决定：<技术选型、取舍>
- 后续：<没做完的、想到的改进>
```

下次同类需求先翻 `docs/notes/`，避免重复调研。

## 轻重怎么判断
| 情况 | 模式 |
|---|---|
| 一个下午能做完、个人用、原型 | 轻量（默认） |
| 多人协作、要上线、要长期维护 | 重：启用 Superpowers 全流程；需要规格文档时再考虑 Spec Kit / OpenSpec |

拿不准时用轻量模式，并在第 3 步的小计划里说一句"如果要做大，可以切到完整流程"。

## 原则
- 用户在对话里的指示优先于这里的流程。
- 搜索和计划都是为了少写冤枉代码，不是为了走流程：每一步都尽量短。
