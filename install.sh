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

# 各工具的全局 skills 目录：只有检测到这个工具装过（父目录存在）才链接
agent_skill_dirs() {
  [[ -d "$HOME/.codex" || -d "$HOME/.agents" ]] && echo "$HOME/.agents/skills"  # Codex、Cline、Zed、Warp 等共用
  [[ -d "$HOME/.cursor" ]] && echo "$HOME/.cursor/skills"
  [[ -d "$HOME/.config/opencode" ]] && echo "$HOME/.config/opencode/skills"
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
  --update)    sync_repos; link_skills; setup_claude_code ;;
  --uninstall) uninstall ;;
  "")          sync_repos; setup_claude_code; link_skills; install_scheduler; log "完成" ;;
  *)           echo "用法: install.sh [--update|--uninstall]"; exit 1 ;;
esac
