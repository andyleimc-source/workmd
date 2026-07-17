#!/usr/bin/env bash
# SessionEnd hook：会话结束时，若有未提交改动则自动 commit 一个快照。
# 安全网，不 push（push 手动）。message 带 [auto] 前缀，方便事后 squash/改写。
set -uo pipefail   # 注意：不开 -e，git 失败要自己兜住，绝不能让 hook 把锁/状态留坏

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0

# 不在 git 仓库就退出
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# --- 清理僵尸锁 -----------------------------------------------------------
# 上一次 commit 被中断（会话被 kill / 进程崩溃）会留下 .git/index.lock，
# 之后启动跑 git 操作撞上它会一直卡住。这里在干活前先清掉「无人持有」的死锁。
clear_stale_lock() {
  local lock="$1"
  [ -e "$lock" ] || return 0
  # lsof 能查到持有者 = 真有 git 在跑，别动
  if command -v lsof >/dev/null 2>&1 && lsof "$lock" >/dev/null 2>&1; then
    return 1
  fi
  # 无人持有 → 死锁，删掉
  rm -f "$lock"
  return 0
}

GITDIR="$(git rev-parse --git-dir 2>/dev/null)"
if [ -n "${GITDIR:-}" ]; then
  if ! clear_stale_lock "$GITDIR/index.lock"; then
    # 锁还被人持有，说明真有 git 进程在跑，本次不动，安静退出
    exit 0
  fi
fi
# --------------------------------------------------------------------------

# 无改动就退出
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

STAMP="$(date '+%Y-%m-%d %H:%M')"
git add -A || exit 0
git commit -m "[auto] session-end snapshot ${STAMP}" --quiet || true
exit 0
