---
name: prior-art-first
description: "Use when the user proposes a product idea, feature, tool or crawler to build, or before adding a dependency, integration or utility that may already exist. Checks which search channels work, searches the repo, package registries, MCP servers, skills, GitHub and the web, scores candidates, then recommends adopt / extend / compose / build before any code."
---

# 先搜开源，再动手（Prior Art First）

用户提出一个想法、提案或"我想做一个 X"时，**不要直接写代码**。先找现成方案，用调研结果决定：直接用、包一层、组合几个，还是自己写。

搜索流程参考了 [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) 的 `search-first` skill（MIT）。

## 何时触发
- 用户描述一个要做的产品、功能、工具、脚本、爬虫、自动化流程
- 用户说"我想做 / 能不能做 / 有个想法"
- 准备加一个依赖、接一个外部服务，或者要写一个"工具函数 / 帮助类 / 封装层"之前
- 不触发：修一个具体 bug、改一行配置、用户明确说"别搜了直接写"

## 总流程

```
0. 渠道自检    先确认哪些搜索渠道能用，不能用的如实说
1. 拆需求      把提案拆成可搜的关键词和硬约束
2. 并行搜索    仓库本身 / 本机已装 / 包管理器 / MCP 和 skill / GitHub / 网页 / 官方 API
3. 评估打分    每个候选按 6 项打分，至少读 1–2 个最佳候选的源码
4. 决策        直接用 / 包一层 / 组合 / 自己写
5. 出报告停下  等用户选，选定后才写代码；结论记进 docs/notes/
```

## 第 0 步：渠道自检
只检查和这次需求相关的渠道。查不了的渠道，报告里要写明"没查"，**不能说成"没找到"**。

| 渠道 | 怎么确认能用 | 不能用时 |
|---|---|---|
| 仓库本身 | `rg --files`、针对性的 `rg` 搜索 | 说明只看了能看到的文件 |
| 本机已装的 skill / MCP | 看当前可用的工具和 skill 列表；`ls ~/.claude/skills ~/.agents/skills`；看 `~/.claude/settings.json`、项目 `.mcp.json` | 说明没有本地清单可查 |
| 包管理器 | `npm --version`、`python3 -m pip --version` 或项目自己的包管理器 | 改用网页搜索，不要声称查过注册表 |
| GitHub | `gh auth status`，或有 GitHub MCP 工具 | 用网页搜索和本地 git 历史 |
| 网页搜索 | 有 WebSearch / WebFetch 之类工具 | 说明没有联网搜索 |
| 官方文档 | Context7 MCP（lkyx 套装自带）或网页 | 退回网页搜索 |

## 第 1 步：先翻自己的笔记，再拆需求（不超过 5 行）
- 项目里有 `docs/notes/` 就先看有没有同类需求的调研记录，有就在它的基础上补充。
- 核心要解决的问题是什么（一句话）
- 关键能力拆成 2–4 个关键词组（中英文都写，英文为主），每组再想 2–3 个同义词
- 硬约束：语言 / 运行环境 / 许可证 / 是否要自托管 / 预算

## 第 2 步：并行搜索
所有渠道的查询一次性并行发出，不要一个一个等。

### 快速模式（小需求，直接在对话里做）
写一个工具函数、加一个小功能之前，按顺序过一遍：
1. **仓库里已经有了吗？** 用 `rg` 搜相关模块和测试。
2. **本机已经装了能做这件事的 skill 或 MCP 吗？** 看当前工具列表和 skill 列表。
3. **是常见问题吗？** 搜 npm / PyPI / crates / Go 包。
4. **有现成的 MCP server 或 skill 吗？** 搜 MCP 目录、skill 市场。
5. **GitHub 上有维护中的实现或模板吗？** 搜仓库和代码。

### 完整模式（产品想法、新项目、不确定有没有现成方案）
覆盖下面全部渠道：
1. **GitHub 仓库**：`gh search repos "<关键词>" --sort stars --limit 10`，以及 `topic:<词>`；每组关键词再试 2–3 个同义词
2. **GitHub 代码**：`gh search code "<关键 API 或函数名>"`，找别人写过的小脚本、片段、gist
3. **Awesome 列表**：搜 `awesome-<领域>`，从中挑候选
4. **包管理器**：npm / PyPI / crates / Go pkg 搜同类能力的库
5. **MCP / skill / 插件**：给 Agent 用的能力，先搜现成的 MCP server、Claude Code 插件、skill
6. **官方文档 / API**：目标平台有没有官方 API、SDK、导出功能（往往比爬虫更好）
7. **网页和社区**："<问题> open source"、"<问题> alternative"、"how to <问题> github"；再看 Hacker News / Reddit / V2EX 的讨论

候选很多时可以派 1–2 个子 agent 分别跑不同渠道，但只在用户或 CLAUDE.md 允许时这么做。子 agent 的提示词这样写：

```
调研现成方案：<需求描述>
语言/框架：<...>
约束：<许可证、自托管、预算...>
要搜：仓库内、npm/PyPI、MCP server、Claude Code skill/插件、GitHub、网页
返回：候选对比表（链接、★数、最近更新、许可证、匹配度、缺什么）+ 推荐
没能查的渠道要单独列出来
```

## 第 3 步：评估打分
每个候选按下面 6 项各打 1–5 分，总分写进报告：

| 项 | 看什么 |
|---|---|
| 匹配度 | 覆盖了需求的百分之多少，缺什么 |
| 维护 | 最近一次提交、release、issue 响应速度 |
| 社区 | star 趋势、使用者多不多、有没有大项目在用 |
| 文档 | README、示例、API 文档是否够上手 |
| 许可证 | MIT / Apache 可放心；GPL / AGPL 要提醒；没有许可证不能直接拿来用 |
| 依赖和体量 | 是轻量库还是重型平台，引入了多少依赖 |

另外两条硬检查，不过关就不推荐：
- **真能用**：不要只看 README，至少打开 1–2 个最佳候选的核心源码确认。
- **合规**：爬虫类要看目标站点 ToS、robots.txt，以及有没有官方 API。

## 第 4 步：决策

| 情况 | 决策 |
|---|---|
| 完全匹配、维护良好、许可证宽松 | **直接用**：安装或配置好就用 |
| 部分匹配、底子好 | **包一层**：装上它，再写一层薄封装补上缺的 |
| 好几个都只覆盖一部分 | **组合**：拼 2–3 个小库 |
| 没有合适的 | **自己写**：但要参考调研里看到的实现和坑 |

## 第 5 步：出报告，然后停下来等用户选
格式（简洁，中文）：

```
## 提案：<一句话>
### 结论
推荐：<直接用 X / 给 Y 包一层 / 组合 A+B / 自己写>，理由一句话。
### 查了哪些渠道
已查：<仓库、npm、GitHub、MCP…>　没查：<渠道 + 原因>
### 候选
1. <名字>（链接，★数，最近更新，许可证，总分 x/30）：能做什么，缺什么
2. ...
### 几条路
- 直接用：<怎么用，工作量>
- 包一层 / 组合：<改哪里，工作量>
- 自己写：<为什么值得，可借鉴哪些实现>
### 风险
<许可证、维护、合规、ToS>
```

- 搜不到合适的，就写清楚"已搜过 X / Y / Z 渠道，没有合适方案"，列出可借鉴的局部实现，再进入自己写。
- 用户选定后才开始写代码。
- 调研结论写进项目的 `docs/notes/<YYYY-MM-DD>-<主题>.md`（格式见 `lkyx-workflow`），下次同类需求先查这里。

## 示例

```
需求：检查 Markdown 里的失效链接
搜索：npm "markdown dead link checker"
找到：textlint-rule-no-dead-link（总分 27/30）
决策：直接用，npm install textlint-rule-no-dead-link
结果：不用写任何自定义代码
```

```
需求：校验项目配置文件是否符合 schema
搜索：npm "json schema validator cli"
找到：ajv-cli（总分 25/30）
决策：包一层，装 ajv-cli，自己只写一份项目 schema
结果：1 个包 + 1 个 schema 文件，没有自写校验逻辑
```

```
需求：让 Agent 能查某个库的最新文档
搜索：MCP 目录、本机已装 MCP
找到：Context7 MCP，lkyx 套装已经装了
决策：直接用，不写爬文档的脚本
```

## 反面清单
- **直接写代码**：没查有没有现成的就开始写工具函数
- **忘了 MCP 和 skill**：没看本机和市场上有没有现成的 MCP 或 skill
- **悄悄跳过渠道**：某个渠道查不了，却报告"没找到"
- **封装过头**：给一个库包了太厚的一层，把它的好处都包没了
- **依赖臃肿**：为了一个小功能装一个巨大的包

## 原则
- 搜索是为了少写代码，不是为了拖延：单次调研控制在 10–15 分钟内，候选列 3–5 个即可。
- 自己写不是失败：调研的价值在于知道别人怎么做、踩过什么坑。
- 抓取公开数据前先找官方 API；尊重 ToS 和 robots.txt。
