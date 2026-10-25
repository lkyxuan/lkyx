# lkyx

我的个人开发 harness，以 Claude Code 插件的形式发布。装一次，所有项目都按同一套流程开发：

**澄清 → 先搜开源 → 一页小计划 → 实现 → 记一笔**

默认是轻量模式，适合个人快速迭代；项目做大时再调用 [Superpowers](https://github.com/obra/superpowers) 的完整流程。

## 安装

在 Claude Code 里执行（用户级安装，一次即可，所有项目通用）：

```bash
# 1. 本仓库
/plugin marketplace add lkyxuan/lkyx
/plugin install lkyx@lkyx

# 2. Superpowers（流程里的澄清、计划、TDD 等步骤会用到，可选但推荐）
/plugin install superpowers@claude-plugins-official
```

然后在每个产品仓库根目录放一份 CLAUDE.md，模板见 [`templates/CLAUDE.md`](templates/CLAUDE.md)，只写这个项目自己的东西（技术栈、怎么跑、怎么测）。

> 如果你已经在 claude.ai 的 skills 里保存过 `prior-art-first`，装了本插件后可以删掉那份，避免两份内容不一致。

## 里面有什么

| 路径 | 作用 |
|---|---|
| `skills/lkyx-workflow/` | 总入口：规定步骤顺序和轻重，决定什么时候调用哪个 skill |
| `skills/prior-art-first/` | 先搜 GitHub、awesome 列表、包管理器、官方 API，出调研报告再决定复用还是自己写 |
| `skills/dev-techniques/` | 从我过往对话里挖出来的开发技巧（只收技巧，不收技术选型） |
| `skills/harvest-techniques/` | 收尾或定期复盘时，从对话里找新的技巧补进 `dev-techniques` |
| `templates/CLAUDE.md` | 产品仓库用的 CLAUDE.md 模板 |
| `docs/notes/` | 这个 harness 自己的设计记录 |

## 流程里谁负责哪一步

| 步骤 | 轻量（默认） | 大项目 |
|---|---|---|
| 澄清 | 对话里问 2–3 个问题 | Superpowers `brainstorming` |
| 先搜开源 | `prior-art-first` | `prior-art-first` |
| 计划 | 对话里 5–10 行 | Superpowers `writing-plans` |
| 实现 | 直接写，跑通验证 | Superpowers TDD / subagent-driven-development |
| 记一笔 | `docs/notes/` | `docs/notes/` |

## 以后可以加

- 想强制每次都走流程：加一个 SessionStart hook，开场提醒使用 `lkyx-workflow`
- 代码审查、发版、部署等自己的规范，作为新 skill 放进 `skills/`
- 定期跑一次 `harvest-techniques`，让 `dev-techniques` 越用越贴合自己
- 改了 skill 后把 `.claude-plugin/plugin.json` 的 `version` 加一，然后在 Claude Code 里 `/plugin marketplace update lkyx`
