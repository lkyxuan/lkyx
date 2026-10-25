---
name: verification-loop
description: "Use before delivering any finished feature, fix or refactor, before pushing or opening a PR, and after each major chunk of a long task. Runs build, type check, lint, tests, a secret scan, a diff review and a real end-to-end run, then writes a PASS/FAIL verification report with evidence."
---

# 交付前验收清单（Verification Loop）

`dev-techniques` 第 6 条"自己验收完再交付"的具体做法。做完一个功能、一次修复或重构，在交付、推送、提 PR 之前按顺序跑一遍，最后给出验收报告。

参考了 [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) 的 `verification-loop` skill（MIT）。

## 什么时候用
- 一个功能、修复或重构做完，准备交付之前
- 推送或提 PR 之前
- 长任务里每做完一大块（一个模块、一个页面），先验这一块再往下走

项目没有的环节（比如没有类型检查、没有测试）直接标"不适用"，不要为了过这张清单去新建测试体系。

## 七个环节

先看项目自己怎么跑这些命令：`package.json` 的 scripts、`Makefile`、`pyproject.toml`、项目 CLAUDE.md。下面只是常见写法。输出长的命令用 `| tail -n 30` 截断，但要加 `set -o pipefail`，免得截断吞掉失败状态。

### 1. 构建
```bash
set -o pipefail
npm run build 2>&1 | tail -n 30      # 或 pnpm build / cargo build / go build ./...
```
构建失败就停下来先修，后面的环节没有意义。

### 2. 类型检查
```bash
set -o pipefail
npx --no-install tsc --noEmit 2>&1 | head -n 30   # TypeScript
pyright . 2>&1 | head -n 30                       # Python
```

### 3. Lint
```bash
set -o pipefail
npm run lint 2>&1 | head -n 30        # 或 ruff check . / cargo clippy / shellcheck *.sh
```

### 4. 测试
```bash
set -o pipefail
npm test 2>&1 | tail -n 50            # 或 pytest / go test ./... / cargo test
```
报告通过数、失败数。项目本来就有覆盖率要求就按项目的来，没有就不额外设门槛。

### 5. 密钥和调试残留扫描
只扫这次改动的文件：
```bash
git diff --name-only HEAD | xargs grep -nE '(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|api[_-]?key\s*[:=]|password\s*[:=]|BEGIN [A-Z ]*PRIVATE KEY)' 2>/dev/null | head -n 20
git diff --name-only HEAD | xargs grep -nE '(console\.log|debugger;|print\(.*DEBUG|TODO: remove)' 2>/dev/null | head -n 20
```
命中真密钥就停下来，先移走再继续；调试残留按需清掉。

### 6. 看一遍 diff
```bash
git status --short
git diff --stat HEAD
```
逐个文件看：有没有改到不该改的地方、遗漏的错误处理、没考虑的边界情况、测试用的临时资源有没有清掉（`dev-techniques` 第 4 条）。

### 7. 真实跑一遍
在用户真实的账号、数据、机器或浏览器里把完整链路跑通，而不只是单元测试：
- 命令行工具 / 脚本：用真实参数跑一次，贴输出
- 网页 / 界面：打开页面操作一遍，截图或给预览链接（lkyx 套装带了 Playwright MCP）
- 接口 / 服务：真实请求一次，贴返回
- 安装脚本：在干净环境或用户机器上跑一次

跑不了的部分要明确写出来是哪一段、为什么。

## 验收报告

跑完给出这张表，作为交付消息的一部分：

```
验收报告
构建：     通过 / 失败 / 不适用
类型：     通过 / 失败（x 个错误）/ 不适用
Lint：     通过 / 失败（x 个警告）/ 不适用
测试：     通过 / 失败（x/y 通过）/ 不适用
密钥扫描： 通过 / 发现 x 处
Diff：     改了 x 个文件，已逐个看过
真实运行： 通过（证据：截图 / 链接 / 输出）/ 未验证：<哪一段，为什么>

结论：可以交付 / 还不能交付
待修：
1. ...
```

- 有任何一项失败，结论就是"还不能交付"：先修，修完从失败的那一环重新跑。
- 同一个失败修了两三次还过不去，按 `dev-techniques` 第 7 条换路，不要硬试。
- 交付消息第一句仍然是"成没成"，验收报告跟在后面。
