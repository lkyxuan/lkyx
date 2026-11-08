<lkyx>
本机装了 lkyx 个人开发 harness。用户描述一个要做的新东西（产品想法、功能、工具、脚本、爬虫、自动化）时，先用 `lkyx-workflow` skill：澄清 → `prior-art-first` 先搜开源并等用户选方案 → 一页小计划 → 实现（按 `dev-techniques`）→ 记一笔。用户不需要说"用 lkyx"。用户明确说跳过调研时才跳过。修具体 bug、改配置、纯问答不走这套流程。

和 Superpowers 的关系：以 `lkyx-workflow` 为准，默认轻量模式。Superpowers 的 brainstorming、writing-plans、TDD、subagent-driven-development 等只在 `lkyx-workflow` 判断为大项目、或用户要求时才用；小任务不要因为 Superpowers 的提示就走完整重流程。

mstack 只在用户输入 `/mstack` 时用，不要自己加载；遇到现有代码上的硬活（难查的 bug、性能、大重构）可以建议用户输入 `/mstack`。用户输入了 `/mstack` 就按 mstack 走，lkyx 流程让开。
</lkyx>
