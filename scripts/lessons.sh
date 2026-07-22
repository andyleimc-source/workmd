#!/usr/bin/env bash
# lessons.sh [关键词 | P0X | 项目名]
# 开工前把「这块已经踩过的坑」顶到眼前，别靠脑子记，也别靠 AI 临场回忆。
# 只读、无副作用。不建新库——直接扫教训本来就住的地方：
#   assets/docs/*.md（你的 SOP / 规范 / 长期文档），以及（给了项目时）该项目的 md。
# 教训标记：⚠ / 坑 / 踩过 / 别再 / 不要再 / 历史教训 / 禁止 / 血泪
#
# 用法：
#   ./scripts/lessons.sh              列出全部教训行（按文件分组）
#   ./scripts/lessons.sh 邮件          只看含「邮件」的教训（关键词命中文件名则出该文件全部）
#   ./scripts/lessons.sh P03          连该项目的 md 一起扫（CLAUDE/handoff/progress/plan）
#
# 怎么让它有用：写文档时把「别再犯」的点用上面那些词标记出来，它才抓得到。
# 建议在 CLAUDE.md 里立规矩：定位到某项目/开一个新任务前，先跑本脚本。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 0
ARG="${1:-}"

MARK='⚠|坑|踩过|别再|不要再|历史教训|禁止|血泪'

# 候选文件：跨项目的文档永远扫；给了项目名再把对应目录的 md 纳入
FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(ls assets/docs/*.md 2>/dev/null)
if [ -n "$ARG" ]; then
  match="$(ls -d projects/${ARG}* projects/*${ARG}* 2>/dev/null | head -1 || true)"
  if [ -n "$match" ]; then
    while IFS= read -r f; do FILES+=("$f"); done < <(
      ls "$match"/CLAUDE.md "$match"/handoff.md "$match"/progress.md "$match"/plan.md 2>/dev/null
    )
  fi
fi

hits=0
for f in ${FILES[@]+"${FILES[@]}"}; do
  [ -f "$f" ] || continue
  # 关键词命中文件路径 → 出该文件全部教训；否则只留同时含关键词的教训行
  if [ -n "$ARG" ] && ! echo "$f" | grep -iqF "$ARG"; then
    lines="$(grep -nE "$MARK" "$f" 2>/dev/null | grep -iF "$ARG" || true)"
  else
    lines="$(grep -nE "$MARK" "$f" 2>/dev/null || true)"
  fi
  [ -z "$lines" ] && continue
  echo "── $f"
  echo "$lines" | sed 's/^/  /'
  echo
  hits=$((hits+1))
done

if [ "$hits" = "0" ]; then
  if [ -n "$ARG" ]; then
    echo "（没扫到教训标记：关键词「${ARG}」。教训用 ⚠/坑/踩过/别再/禁止 等词标记，才会被顶出来。）"
  else
    echo "（没扫到教训标记。教训用 ⚠/坑/踩过/别再/禁止 等词标记，才会被顶出来。）"
  fi
fi
