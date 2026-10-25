# lkyx

我的个人开发 harness，以 Claude Code 插件的形式发布。装一次，所有项目都按同一套流程开发：

**澄清 → 先搜开源 → 一页小计划 → 实现 → 记一笔**

默认是轻量模式，适合个人快速迭代；项目做大时再调用 [Superpowers](https://github.com/obra/superpowers) 的完整流程。

## 安装

一条命令装上整套（lkyx + 清单里的第三方插件和 skill），之后自动更新：

```bash
curl -fsSL https://raw.githubusercontent.com/lkyxuan/lkyx/main/install.sh | bash
```

它会做这些事：

| 工具 | 怎么装 | 怎么更新 |
|---|---|---|
| Claude Code | 装 `bundle.json` 里列的插件，并给 lkyx 市场打开自动更新 | Claude Code 启动时自动拉新版本 |
| Codex、Cursor、Hermes、Gemini CLI、Windsurf 等 60 多个 Agent | 把 skill 软链接到各自的 skills 目录（只链接本机装过的；以后新装的 Agent 会在下次每日更新时自动补上） | 每天自动 `git pull`（macOS 用 launchd，Linux 用 cron），软链接指向的内容随之更新 |

代码放在 `~/.lkyx`。卸载：`~/.lkyx/install.sh --uninstall`，Claude Code 插件在 `/plugin` 里卸载。

只想在 Claude Code 里手动装也可以：

```bash
/plugin marketplace add lkyxuan/lkyx
/plugin install lkyx@lkyx
/plugin install superpowers@lkyx
```

然后在每个产品仓库根目录放一份 CLAUDE.md，模板见 [`templates/CLAUDE.md`](templates/CLAUDE.md)，只写这个项目自己的东西（技术栈、怎么跑、怎么测）。

> 如果你已经在 claude.ai 的 skills 里保存过 `prior-art-first`，装了本插件后可以删掉那份，避免两份内容不一致。

## 套装里有什么

清单在 [`bundle.json`](bundle.json)：

- **lkyx**：本仓库的 skill（见下表）
- **Superpowers**：头脑风暴、写计划、TDD、子 agent 开发，大项目模式会用到
- **MCP 服务器**：暂时没有

### 往套装里加东西

| 要加的 | 改哪里 |
|---|---|
| Claude Code 插件 | `bundle.json` 的 `claude_plugins` 加一项 `"plugin": "名字@市场"`；市场不是 lkyx 或官方的，再加 `"marketplace_repo": "owner/repo"`。也可以像 Superpowers 一样，直接在 `.claude-plugin/marketplace.json` 里登记，变成 `名字@lkyx` |
| 给其他工具用的 skill 仓库 | `bundle.json` 的 `skill_repos` 加一项 `name`、`repo`、`skills_dir` |
| MCP 服务器 | 仓库根目录建 `.mcp.json`（格式同 Claude Code 的 `.mcp.json`），lkyx 插件启用时会自动带上 |

改完把 `.claude-plugin/plugin.json` 的 `version` 加一，推到 main。各台电脑会在下次自动更新时装上新加的东西。

## lkyx 自己的 skill

| 路径 | 作用 |
|---|---|
| `skills/lkyx-workflow/` | 总入口：规定步骤顺序和轻重，决定什么时候调用哪个 skill |
| `skills/prior-art-first/` | 先搜 GitHub、awesome 列表、包管理器、官方 API，出调研报告再决定复用还是自己写 |
| `skills/dev-techniques/` | 从我过往对话里挖出来的开发技巧（只收技巧，不收技术选型） |
| `skills/harvest-techniques/` | 收尾或定期复盘时，从对话里找新的技巧补进 `dev-techniques` |
| `hooks/` | Claude Code 每次开新会话时提醒：遇到新东西要做，自动走 `lkyx-workflow`，不用你说“用 lkyx” |
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

- 代码审查、发版、部署等自己的规范，作为新 skill 放进 `skills/`
- 定期跑一次 `harvest-techniques`，让 `dev-techniques` 越用越贴合自己
