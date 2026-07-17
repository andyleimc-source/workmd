#!/usr/bin/env bash
# worker-review.sh — 施工方的活的审查闭环
#
#   scripts/worker-review.sh          # 列出水位线(tag worker-reviewed)之后施工方干的 commit + diffstat
#   scripts/worker-review.sh --pass   # 本批全部处理完(含返工已合并) → 挪水位线到 HEAD，闭环
#
# 识别施工方的活走双通道取并集：
#   硬标记 author=<施工方> （worker-do.sh 注入）∪ Co-Authored-By 署名
#
# 施工方名字可换：export WORKER_NAME=<名字>（默认 agy），要与 worker-do.sh 一致。
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

TAG=worker-reviewed
WORKER="${WORKER_NAME:-agy}"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || {
  echo "❌ 没有 tag ${TAG}。初始化（当前起点即豁免历史）: git tag $TAG"; exit 1; }

if [[ "${1:-}" == "--pass" ]]; then
  git tag -f "$TAG" HEAD >/dev/null
  echo "✓ 水位线 $TAG 已挪到 $(git rev-parse --short HEAD)，本轮审查闭环。"
  exit 0
fi

COMMITS=$( { git log --author="$WORKER" --format=%H "$TAG"..HEAD
             git log --grep="Co-Authored-By: $WORKER" --format=%H "$TAG"..HEAD; } | sort -u )

echo "水位线 $TAG = $(git rev-parse --short "$TAG")（$(git log -1 --format=%ad --date=short "$TAG")）"
N=0
for h in $(git rev-list --reverse "$TAG"..HEAD); do
  echo "$COMMITS" | grep -q "$h" || continue
  N=$((N+1))
  echo ""
  git --no-pager show --stat --date=short --format="── [$N] %h %ad %s（author: %an）" "$h"
done

echo ""
if [[ $N -eq 0 ]]; then
  echo "✓ 水位线之后没有施工方的新活，无需审查。"
else
  echo "共 $N 条待审。司机流程：① 粗筛可派更便宜的模型读 diff，精读标红处 → ② 小修直接改；成块问题在原卡追加「## 返工 R<n>」跑 worker-do.sh 返工 → ③ 全处理完跑 scripts/worker-review.sh --pass 挪水位线。"
fi
