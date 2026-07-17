#!/usr/bin/env bash
# SessionStart hook：会话开始时，若发现「疑似做完但没归档」的项目，且距上次提醒 >= 7 天，
# 就把候选注入上下文，让 AI 在对话自然告一段落时问用户要不要归档。
#
# 绝不自动归档；限频，避免每次会话都唠叨。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

STATE="${ROOT}/assets/.archive-nudge-state"     # 只存一行：上次提醒的 epoch 秒
INTERVAL_DAYS=7
NOW="$(date +%s)"

# 限频：距上次提醒不足 INTERVAL_DAYS 天就安静退出
if [ -f "$STATE" ]; then
  last="$(cat "$STATE" 2>/dev/null || echo 0)"
  [ -z "$last" ] && last=0
  if [ $(( (NOW - last) / 86400 )) -lt "$INTERVAL_DAYS" ]; then
    exit 0
  fi
fi

# 跑探测器（可用 ARCHIVE_NUDGE_STALE_DAYS 覆盖阈值，便于测试）
CANDS="$("${ROOT}/scripts/detect-done-projects.sh" ${ARCHIVE_NUDGE_STALE_DAYS:-} 2>/dev/null || true)"
[ -z "$CANDS" ] && exit 0

# 有候选 → 组装提醒文本
LINES="$(echo "$CANDS" | awk -F'|' '{printf "  - %s（%s）\n", $1, $3}')"
MSG="【归档提醒·每周至多一次】以下项目疑似已完成但可能忘了归档：
${LINES}
请在当前对话自然告一段落时（不要打断用户手头的事）顺口问一句：这些项目是收尾了还是还在推进/卡住？确认收尾的用 \`scripts/finish-project.sh <P0X>\` 整包归档；用户说「先别问 P0X」就往 assets/.archive-nudge-snooze 加一行「P0X <一个月后的日期>」。绝不自动归档。"

# 更新限频时间戳
echo "$NOW" > "$STATE"

# 以 SessionStart additionalContext 形式注入
python3 - "$MSG" <<'PY'
import json, sys
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": sys.argv[1]
  }
}))
PY
exit 0
