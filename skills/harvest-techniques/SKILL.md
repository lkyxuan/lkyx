---
name: harvest-techniques
description: "Use at the end of a development session, or when the user asks to review past conversations, to find development techniques worth adding to the lkyx harness (dev-techniques). Looks for places the user corrected the agent or repeated an instruction."
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

## 怎么提炼
每条候选写成：

```
### <技巧名，一句话>
- 什么时候：<场景>
- 怎么做：<具体动作>
- 来源：<哪次对话，日期，用户原话的大意>
```

要能跨项目复用。只在一个项目里成立的，降级成项目笔记。

## 怎么落地
1. 把 2–5 条候选给用户看，说明每条的来源。
2. 用户同意的，加进 `skills/dev-techniques/SKILL.md` 对应的分组（动手前 / 做的时候 / 交付时 / 对接），和已有条目重复的就合并。
3. `.claude-plugin/plugin.json` 的 `version` 加一，提 PR。
