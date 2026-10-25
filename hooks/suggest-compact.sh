#!/usr/bin/env bash
# 在 Edit / Write 前检查上下文大小，到了阈值就提醒在下一个阶段分界处手动 /compact。
# 思路来自 Everything Claude Code 的 strategic-compact（MIT），这里用纯 bash 重写，不依赖 node。
#
# 两个信号：
# - 上下文 token 数（主要）：读会话记录里最新一条 usage，
#   200k 窗口在 160k 时提醒；超过 200k 视为 1M 窗口，250k 时提醒；之后每涨 60k 再提醒一次。
# - 工具调用次数（次要）：第 50 次提醒，之后每 25 次提醒一次。
#
# 可用环境变量调整：COMPACT_CONTEXT_THRESHOLD（设为 0 关闭 token 信号）、
# COMPACT_CONTEXT_INTERVAL、COMPACT_THRESHOLD（设为 0 关闭次数信号）。
# 必须兼容 macOS 自带的 bash 3.2；任何出错都静默退出 0，不能挡住工具调用。

input=$(cat 2>/dev/null) || exit 0

json_str() {
  printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

session_id=$(json_str session_id | tr -cd 'A-Za-z0-9_-')
[ -n "$session_id" ] || session_id=default
transcript=$(json_str transcript_path)

state_dir="${TMPDIR:-/tmp}"
state_dir="${state_dir%/}/lkyx-compact"
mkdir -p "$state_dir" 2>/dev/null || exit 0
# 清掉 14 天前的状态文件
find "$state_dir" -type f -mtime +14 -delete 2>/dev/null

messages=""
add_msg() {
  if [ -n "$messages" ]; then messages="$messages\\n$1"; else messages="$1"; fi
}

# 信号一：上下文 token 数
if [ -n "$transcript" ] && [ -f "$transcript" ] && [ "${COMPACT_CONTEXT_THRESHOLD:-}" != "0" ]; then
  usage=$(tail -n 400 "$transcript" 2>/dev/null | grep '"usage"' | tail -n 1)
  if [ -n "$usage" ]; then
    num() { printf '%s' "$usage" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9]*" | head -n 1 | grep -o '[0-9]*$'; }
    a=$(num input_tokens); b=$(num cache_read_input_tokens); c=$(num cache_creation_input_tokens)
    tokens=$(( ${a:-0} + ${b:-0} + ${c:-0} ))
    if [ "$tokens" -gt 200000 ] || printf '%s' "$usage" | grep -q '\[1m\]'; then
      window=1000000; threshold=${COMPACT_CONTEXT_THRESHOLD:-250000}
    else
      window=200000; threshold=${COMPACT_CONTEXT_THRESHOLD:-160000}
    fi
    interval=${COMPACT_CONTEXT_INTERVAL:-60000}
    case "$threshold$interval" in *[!0-9]*) threshold=160000; interval=60000 ;; esac
    [ "$interval" -gt 0 ] || interval=60000
    if [ "$tokens" -ge "$threshold" ]; then
      bucket="$window:$(( (tokens - threshold) / interval ))"
      bucket_file="$state_dir/bucket-$session_id"
      last=$(cat "$bucket_file" 2>/dev/null)
      if [ "$bucket" != "$last" ]; then
        printf '%s' "$bucket" > "$bucket_file"
        pct=$(( tokens * 100 / window ))
        add_msg "[lkyx] 上下文约 $(( tokens / 1000 ))k tokens（约占 ${pct}%）。在下一个阶段分界处（调研完、一个模块做完、换任务前）手动 /compact，先把计划和进度写清楚再压缩。"
      fi
    fi
  fi
fi

# 信号二：工具调用次数
count_threshold=${COMPACT_THRESHOLD:-50}
case "$count_threshold" in ''|*[!0-9]*) count_threshold=50 ;; esac
if [ "$count_threshold" -gt 0 ]; then
  count_file="$state_dir/count-$session_id"
  count=$(cat "$count_file" 2>/dev/null)
  case "$count" in ''|*[!0-9]*) count=0 ;; esac
  count=$(( count + 1 ))
  printf '%s' "$count" > "$count_file"
  if [ "$count" -eq "$count_threshold" ] || { [ "$count" -gt "$count_threshold" ] && [ $(( (count - count_threshold) % 25 )) -eq 0 ]; }; then
    add_msg "[lkyx] 本会话已编辑 ${count} 次。如果正好在阶段分界处，可以考虑 /compact。"
  fi
fi

if [ -n "$messages" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$messages"
fi
exit 0
