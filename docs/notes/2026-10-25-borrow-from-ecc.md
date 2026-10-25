# 借鉴 Everything Claude Code

- 目标：用户听说的"黑客松冠军 skill"查下来是 Everything Claude Code（affaan-m，Anthropic 黑客松冠军，MIT，不是 Cloudflare 的）。挑适合 lkyx 的部分加进来。
- 调研结论：ECC 和 lkyx 同类（插件 + install.sh + 多 Agent），但大而全（71 agent、300 多个 skill）。用户最看中它 `search-first` 写得细。
- 加了什么：
  - `prior-art-first` 按 `search-first` 重写：渠道自检（查不了的如实说）、快速 / 完整两种模式、先查仓库和本机已装的 skill/MCP、6 项打分、直接用 / 包一层 / 组合 / 自己写、示例、反面清单。保留原来的报告格式和"等用户选"。
  - 新 skill `verification-loop`：七个环节 + 验收报告。去掉了 ECC 的 80% 覆盖率门槛，加了"真实跑一遍"。
  - `hooks/suggest-compact.sh`：`strategic-compact` 的纯 bash 版（ECC 原版是 node，依赖它自己的 lib），兼容 bash 3.2。
  - `harvest-techniques` 借 `continuous-learning-v2` 的模型：原子直觉、0.3–0.9 置信度、证据、跨 2 个项目才升级；候选存 `docs/instincts.md`。
- 没收的：ECC 的 TDD 强制、eval 先行（和"直接按最终方案做完整"冲突）；continuous-learning-v2 的工具调用监听 hook + 后台 Haiku 分析（太重，lkyx 已有每周挖技巧的定时任务）。
- 后续：hook 只在云端 Linux 上测过，Mac 上的 bash 3.2 还没实际跑过。
