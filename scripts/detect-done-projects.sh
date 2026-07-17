#!/usr/bin/env bash
# detect-done-projects.sh [STALE_DAYS]
# 扫 projects/P*，找「疑似已完成、可能忘了归档」的候选项目。只读、无副作用。
#
# 判据（保守，避免误报）：
#   A. 停滞 —— 最后一次 git 提交碰这个项目 > STALE_DAYS 天前（默认 21）
#   B. 无进行中 —— projects/PXX/tasks/ 下没有任何 status:in-progress / blocked 的任务
#   命中 = A 且 B。
#
# 用 git 提交日期而非文件 mtime：多设备 git 同步会重置 mtime，git 日期才跨机可靠。
# 输出每行：P0X-slug|停滞天数|理由；无候选则无输出。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 0
STALE_DAYS="${1:-21}"
NOW="$(date +%s)"
SNOOZE="${ROOT}/assets/.archive-nudge-snooze"   # 每行：P0X YYYY-MM-DD（此日期前不提醒）

is_snoozed() {  # $1 = P0X 编号
  [ -f "$SNOOZE" ] || return 1
  local until
  until="$(grep -E "^$1 " "$SNOOZE" 2>/dev/null | awk '{print $2}' | tail -1)"
  [ -n "$until" ] || return 1
  [ "$(date +%Y-%m-%d)" \< "$until" ] || [ "$(date +%Y-%m-%d)" = "$until" ]
}

for dir in projects/P*/; do
  [ -d "$dir" ] || continue
  proj="$(basename "$dir")"
  pcode="${proj%%-*}"
  [ "$pcode" = "P00" ] && continue           # 兜底项目永不建议整包归档
  is_snoozed "$pcode" && continue

  # A. 停滞天数（最后提交碰该项目）
  last_ct="$(git log -1 --format=%ct -- "$dir" 2>/dev/null || true)"
  [ -z "$last_ct" ] && continue              # 从未提交（新建未落盘）→ 跳过
  days=$(( (NOW - last_ct) / 86400 ))
  [ "$days" -lt "$STALE_DAYS" ] && continue

  # B. 无进行中任务
  active=0
  if compgen -G "${dir}tasks/*/progress.md" >/dev/null 2>&1; then
    active="$(grep -lE '^status: (in-progress|blocked)' "${dir}"tasks/*/progress.md 2>/dev/null | wc -l | tr -d ' ')"
  fi
  [ "$active" != "0" ] && continue

  echo "${proj}|${days}|停滞 ${days} 天且无进行中任务"
done
