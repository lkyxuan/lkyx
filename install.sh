#!/usr/bin/env bash
# lkyx 安装 / 自动更新脚本：按 bundle.json 把整套东西装上
#
#   curl -fsSL https://raw.githubusercontent.com/lkyxuan/lkyx/main/install.sh | bash
#
#   install.sh             安装：Claude Code 装插件并打开自动更新；其他工具用软链接 + 每天自动 git pull
#   install.sh --update    拉最新代码、补装清单里新加的东西（定时任务调用的就是这个）
#   install.sh --uninstall 删除软链接和定时任务（Claude Code 插件用 /plugin 卸载）
set -euo pipefail

REPO_URL="https://github.com/lkyxuan/lkyx.git"
LKYX_HOME="${LKYX_HOME:-$HOME/.lkyx}"
VENDOR_DIR="$LKYX_HOME/vendor"
LOG_FILE="$LKYX_HOME/update.log"
PLIST="$HOME/Library/LaunchAgents/com.lkyx.update.plist"
CRON_TAG="# lkyx-auto-update"

log() { echo "[lkyx] $*"; }

# 读 bundle.json：bundle <key> 输出每项一行，字段用 tab 分隔
bundle() {
  python3 - "$LKYX_HOME/bundle.json" "$1" <<'EOF'
import json, sys
b = json.load(open(sys.argv[1]))
for item in b.get(sys.argv[2], []):
    if sys.argv[2] == "claude_plugins":
        print(item["plugin"], item.get("marketplace_repo", ""), sep="\t")
    else:
        print(item["name"], item["repo"], item.get("skills_dir", "skills"), sep="\t")
EOF
}

# 各 Agent 的全局 skills 目录（来自 vercel-labs/skills 的 docs/agents.md，Claude Code 走插件不在这里）
AGENT_SKILL_DIRS=(
  "$HOME/.aider-desk/skills"  # AiderDesk
  "$HOME/.config/agents/skills"  # Amp
  "$HOME/.gemini/antigravity/skills"  # Antigravity
  "$HOME/.gemini/antigravity-cli/skills"  # Antigravity CLI
  "$HOME/.astrbot/data/skills"  # AstrBot
  "$HOME/.autohand/skills"  # Autohand Code CLI
  "$HOME/.augment/skills"  # Augment
  "$HOME/.bob/skills"  # IBM Bob
  "$HOME/.openclaw/skills"  # OpenClaw
  "$HOME/.agents/skills"  # Cline
  "$HOME/.codeartsdoer/skills"  # CodeArts Agent
  "$HOME/.codebuddy/skills"  # CodeBuddy
  "$HOME/.codemaker/skills"  # Codemaker
  "$HOME/.codestudio/skills"  # Code Studio
  "$HOME/.commandcode/skills"  # Command Code
  "$HOME/.continue/skills"  # Continue
  "$HOME/.snowflake/cortex/skills"  # Cortex Code
  "$HOME/.config/crush/skills"  # Crush
  "$HOME/.cursor/skills"  # Cursor
  "$HOME/.deepagents/agent/skills"  # Deep Agents
  "$HOME/.config/devin/skills"  # Devin for Terminal
  "$HOME/.factory/skills"  # Droid
  "$HOME/.firebender/skills"  # Firebender
  "$HOME/.forge/skills"  # ForgeCode
  "$HOME/.gemini/skills"  # Gemini CLI
  "$HOME/.copilot/skills"  # GitHub Copilot
  "$HOME/.config/goose/skills"  # Goose
  "$HOME/.grok/skills"  # Grok Build
  "$HOME/.hermes/skills"  # Hermes Agent
  "$HOME/.inferencesh/skills"  # inference.sh
  "$HOME/.jazz/skills"  # Jazz
  "$HOME/.junie/skills"  # Junie
  "$HOME/.iflow/skills"  # iFlow CLI
  "$HOME/.kilo/skills"  # Kilo Code
  "$HOME/.config/kimchi/harness/skills"  # Kimchi
  "$HOME/.kiro/skills"  # Kiro CLI
  "$HOME/.kode/skills"  # Kode
  "$HOME/.lingma/skills"  # Lingma
  "$HOME/.mcpjam/skills"  # MCPJam
  "$HOME/.minimax/skills"  # MiniMax Code
  "$HOME/.vibe/skills"  # Mistral Vibe
  "$HOME/.moxby/skills"  # Moxby
  "$HOME/.mux/skills"  # Mux
  "$HOME/.config/opencode/skills"  # OpenCode
  "$HOME/.openhands/skills"  # OpenHands
  "$HOME/.ona/skills"  # Ona
  "$HOME/.posit/assistant/skills"  # Posit Assistant
  "$HOME/.qoder/skills"  # Qoder
  "$HOME/.qoder-cn/skills"  # Qoder CN
  "$HOME/.qwen/skills"  # Qwen Code
  "$HOME/.reasonix/skills"  # Reasonix
  "$HOME/.rovodev/skills"  # Rovo Dev
  "$HOME/.roo/skills"  # Roo Code
  "$HOME/.tabnine/agent/skills"  # Tabnine CLI
  "$HOME/.terramind/skills"  # Terramind
  "$HOME/.tinycloud/skills"  # Tinycloud
  "$HOME/.trae/skills"  # Trae
  "$HOME/.trae-cn/skills"  # Trae CN
  "$HOME/.codeium/windsurf/skills"  # Windsurf
  "$HOME/.zcode/skills"  # ZCode
  "$HOME/.zencoder/skills"  # Zencoder
  "$HOME/.neovate/skills"  # Neovate
  "$HOME/.pochi/skills"  # Pochi
  "$HOME/.adal/skills"  # AdaL
)

AGENTS_MD_URL="https://raw.githubusercontent.com/vercel-labs/skills/main/docs/agents.md"
AGENTS_CACHE="$LKYX_HOME/agents.cache"

# 每次安装/更新时从 vercel-labs/skills 拉最新的 Agent 目录表（MIT），
# 新出的 Agent 不用改脚本也能支持；拉不到就用上面内置的列表
refresh_agent_dirs() {
  local md
  md="$(curl -fsSL --max-time 20 "$AGENTS_MD_URL" 2>/dev/null)" || return 0
  python3 -c '
import re, sys, os
home = os.path.expanduser("~")
out = []
for line in sys.stdin:
    m = re.match(r"\| (.+?) \| .*? \| .*? \| `(~/[^`]+)` \|", line)
    if m and "Claude Code" not in m.group(1):
        out.append(m.group(2).rstrip("/").replace("~", home, 1))
if len(out) > 20:
    open(sys.argv[1], "w").write("\n".join(out) + "\n")
' "$AGENTS_CACHE" <<<"$md" || true
}

# 只链接本机装过的 Agent：skills 目录的上一级（工具自己的配置目录）存在才算装过
agent_skill_dirs() {
  local d dirs=("${AGENT_SKILL_DIRS[@]}")
  if [[ -s "$AGENTS_CACHE" ]]; then  # 不用 mapfile：macOS 自带的 bash 3.2 没有
    dirs=()
    while IFS= read -r d; do dirs+=("$d"); done <"$AGENTS_CACHE"
  fi
  for d in "${dirs[@]}"; do
    if [[ "$d" == "$HOME/.agents/skills" ]]; then
      # Codex、Cline、Zed、Warp、Pi 等共用这个目录
      [[ -d "$HOME/.agents" || -d "$HOME/.codex" || -d "$HOME/.cline" || -d "$HOME/.pi" ]] && echo "$d"
    elif [[ -d "$(dirname "$d")" ]]; then
      echo "$d"
    fi
  done
  return 0
}

pull_or_clone() {
  if [[ -d "$2/.git" ]]; then
    git -C "$2" pull --ff-only --quiet
  else
    mkdir -p "$(dirname "$2")"
    git clone --quiet --depth 1 "$1" "$2"
  fi
}

# 本仓库和清单里的第三方 skill 仓库（vendor/ 不进 git）
sync_repos() {
  local name repo dir
  pull_or_clone "$REPO_URL" "$LKYX_HOME"
  while IFS=$'\t' read -r name repo dir; do
    pull_or_clone "$repo" "$VENDOR_DIR/$name"
  done < <(bundle skill_repos)
}

# 所有要链接的 skill 目录：本仓库 skills/ + 每个第三方仓库的 skills_dir
skill_sources() {
  local name repo dir
  printf '%s\n' "$LKYX_HOME"/skills/*/
  while IFS=$'\t' read -r name repo dir; do
    printf '%s\n' "$VENDOR_DIR/$name/$dir"/*/
  done < <(bundle skill_repos)
}

link_skills() {
  local dir skill name target
  while read -r dir; do
    [[ -n "$dir" ]] || continue
    mkdir -p "$dir"
    while read -r skill; do
      [[ -f "$skill/SKILL.md" ]] || continue
      name="$(basename "$skill")"
      target="$dir/$name"
      if [[ -e "$target" && ! -L "$target" ]]; then
        log "跳过 $target：已有同名目录，不是 lkyx 的链接"
        continue
      fi
      ln -sfn "${skill%/}" "$target"
    done < <(skill_sources)
    # 清理已从清单或仓库删掉的 skill 留下的断链
    for target in "$dir"/*; do
      [[ -L "$target" && ! -e "$target" && "$(readlink "$target")" == "$LKYX_HOME"/* ]] && rm -f "$target"
    done
    log "已链接到 $dir"
  done < <(agent_skill_dirs)
}

setup_claude_code() {
  command -v claude >/dev/null 2>&1 || { log "没找到 claude 命令，跳过 Claude Code"; return 0; }
  local plugin repo
  claude plugin marketplace add lkyxuan/lkyx >/dev/null 2>&1 || true
  while IFS=$'\t' read -r plugin repo; do
    [[ -z "$repo" ]] || claude plugin marketplace add "$repo" >/dev/null 2>&1 || true
    if claude plugin install "$plugin" >/dev/null 2>&1; then log "Claude Code：已装 $plugin"; else log "Claude Code：$plugin 安装失败，稍后可手动 /plugin install"; fi
  done < <(bundle claude_plugins)
  # 在用户设置里给 lkyx 市场打开 autoUpdate，Claude Code 启动时会自动拉新版本
  python3 - "$HOME/.claude/settings.json" <<'EOF'
import json, sys, os
p = sys.argv[1]
s = json.load(open(p)) if os.path.exists(p) else {}
m = s.setdefault("extraKnownMarketplaces", {}).setdefault("lkyx", {})
m.setdefault("source", {"source": "github", "repo": "lkyxuan/lkyx"})
m["autoUpdate"] = True
json.dump(s, open(p, "w"), indent=2, ensure_ascii=False)
EOF
  log "Claude Code：已打开 lkyx 自动更新"
}

install_scheduler() {
  local cmd="$LKYX_HOME/install.sh --update"
  if [[ "$(uname)" == "Darwin" ]]; then
    mkdir -p "$(dirname "$PLIST")"
    cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.lkyx.update</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>-lc</string><string>$cmd</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>86400</integer>
  <key>StandardOutPath</key><string>$LOG_FILE</string>
  <key>StandardErrorPath</key><string>$LOG_FILE</string>
</dict></plist>
EOF
    launchctl unload "$PLIST" 2>/dev/null || true
    launchctl load "$PLIST"
    log "已设置每天自动更新（launchd）"
  elif command -v crontab >/dev/null 2>&1; then
    { crontab -l 2>/dev/null | grep -v "$CRON_TAG" || true
      echo "17 9 * * * $cmd >>$LOG_FILE 2>&1 $CRON_TAG"; } | crontab -
    log "已设置每天自动更新（cron）"
  else
    log "没有 launchd 也没有 crontab，请自己定期运行：$cmd"
  fi
}

uninstall() {
  local dir target
  while read -r dir; do
    [[ -n "$dir" ]] || continue
    for target in "$dir"/*; do
      [[ -L "$target" && "$(readlink "$target")" == "$LKYX_HOME"/* ]] && rm -f "$target"
    done
  done < <(agent_skill_dirs)
  if [[ -f "$PLIST" ]]; then launchctl unload "$PLIST" 2>/dev/null || true; rm -f "$PLIST"; fi
  if command -v crontab >/dev/null 2>&1; then
    { crontab -l 2>/dev/null | grep -v "$CRON_TAG" || true; } | crontab -
  fi
  log "已删除软链接和定时任务。Claude Code 插件请在 /plugin 里卸载，代码在 $LKYX_HOME 可以手动删掉。"
}

case "${1:-}" in
  --update)    sync_repos; refresh_agent_dirs; link_skills; setup_claude_code ;;
  --uninstall) uninstall ;;
  "")          sync_repos; refresh_agent_dirs; setup_claude_code; link_skills; install_scheduler; log "完成" ;;
  *)           echo "用法: install.sh [--update|--uninstall]"; exit 1 ;;
esac
