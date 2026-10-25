---
name: harvest-techniques
description: "Use at the end of a development session, or when the user asks to review past conversations, to find development techniques worth adding to the lkyx harness. Records each candidate as a confidence-scored instinct with evidence in docs/instincts.md and promotes it into dev-techniques once it is strong and seen in 2+ projects."
---

# 从对话里挖开发技巧

harness 不靠凭空总结，靠从真实对话里抓。判断标准：**同一件事用户纠正 Agent 两次，或者用户主动提出了一个做法，就值得考虑写进来。**

## 只收技巧，不收这些
- 技术选型偏好（用什么框架、部署在哪）→ 放各项目自己的 CLAUDE.md
- 某个项目特有的事实（端口、路径、账号）→ 放项目 CLAUDE.md 或项目笔记
- 一次性的需求

## 去哪找
1. **当前对话**：收尾时扫一遍本次对话。
2. **最近的云端会话**：有 Claude Code Remote 工具时，用 `list_sessions` 列出最近会话，再对开发类会话用 `list_events`（`kinds: ["user"]`）只读用户消息。
3. **本机会话记录**：在用户电脑上时，Claude Code 的对话存在 `~/.claude/projects/*/` 下的 `.jsonl` 文件里，只看 `type` 为 user 且不是工具结果的消息。

## 找什么信号
- 用户纠正："不要……""你为什么又……""我说的是……"
- 用户重复同一个要求两次以上
- 用户主动提出的做法："要不要先……""你先去……""研究完删掉"
- Agent 走了弯路、返工、被打断的地方

## 怎么提炼：写成一条"直觉"
借鉴 [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) 的 `continuous-learning-v2`（MIT）：每条候选是一个**原子的直觉**，一个触发场景只对应一个动作，带置信度和证据。

```
### <技巧名，一句话>
- 什么时候：<触发场景>
- 怎么做：<具体动作>
- 置信度：0.3 / 0.5 / 0.7 / 0.9
- 出现过的项目：<项目 A、项目 B>
- 证据：
  - <日期，哪个项目/会话，用户原话的大意>
```

### 置信度怎么定
| 分数 | 含义 | 什么情况 |
|---|---|---|
| 0.3 | 试探 | 只出现过一次，或者是 Agent 自己观察到的弯路 |
| 0.5 | 中等 | 用户纠正过一次，或主动提出过一次 |
| 0.7 | 较强 | 同一件事被纠正或要求了两次以上 |
| 0.9 | 几乎确定 | 在多个项目、多次对话里反复出现，用户从没反对过 |

- **加分**：又观察到一次；跨了一个新项目；用户照着做了没纠正。
- **减分**：用户明确反对或纠正了这条做法（直接降到 0.3 以下就删掉）；和已有技巧冲突。

### 只在一个项目里还是到处都成立
- 只在一个项目里成立的（这个项目的目录结构、这个框架的写法）→ 不收进 harness，降级成项目笔记或项目 CLAUDE.md。
- 跨项目都成立的（工作方式、验证方式、沟通方式）→ 才是 harness 要的技巧。
- 拿不准时先当成"只在一个项目里"，等在第二个项目里再出现时再升级。

## 怎么落地
候选都存在 lkyx 仓库的 [`docs/instincts.md`](../../docs/instincts.md)，每次挖完先更新这个文件：新候选追加进去，已有的补证据、调置信度、补项目名。

**升级成正式技巧**（进 `skills/dev-techniques/SKILL.md`）要同时满足：
- 置信度 ≥ 0.7
- 在 2 个以上项目里出现过，或者用户明确说"以后都要这样"

满足的就从 `docs/instincts.md` 移到 `dev-techniques` 对应的分组（动手前 / 做的时候 / 交付时 / 对接），和已有条目重复的就合并。没满足的留在 `docs/instincts.md` 里继续攒证据。

最后：
1. 把这次新增、调整、升级的条目给用户看，说明每条的来源。用户在对话里否决的直接删掉。
2. `.claude-plugin/plugin.json` 和 `.claude-plugin/marketplace.json` 里的 `version` 加一。
3. 推到 main（用户允许 lkyx 直接推 main，不必走 PR）。
