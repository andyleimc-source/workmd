#!/usr/bin/env bash
# finish-project.sh <P0X | 项目完整目录名>
# 整个项目收尾：把 projects/P0X-slug/ 整包 mv 到 archive/P0X-slug/，
# 若 archive 下已有该项目（之前归档过任务），合并进去；frontmatter status→done；
# 更新 codes.md 项目状态 + 顶层 progress.md；git commit。
#
# ⚠ 由用户明确确认「这个项目收尾了」后才跑，AI 绝不自动调用。
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <P0X | 项目完整目录名>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IN="$1"
TODAY="$(date +%Y-%m-%d)"

# 模糊匹配项目目录
if [ -d "${ROOT}/projects/${IN}" ]; then
  PROJ="$IN"
else
  match=$(ls "${ROOT}/projects" 2>/dev/null | grep -E "^${IN}(-|$)" || true)
  count=$(echo "$match" | grep -c . || true)
  if [ "$count" = "1" ]; then PROJ="$match"
  else echo "❌ 项目匹配不唯一或不存在: $IN" >&2; echo "$match" >&2; exit 1; fi
fi

if [ "${PROJ%%-*}" = "P00" ]; then
  echo "❌ P00-misc 是常驻兜底项目，不归档。要归档的是它下面的单个任务（finish-task.sh）。" >&2
  exit 1
fi

SRC="${ROOT}/projects/${PROJ}"
DEST="${ROOT}/archive/${PROJ}"

# frontmatter status→done（用 perl 而非 sed -i：BSD/GNU 语法不同，perl 跨平台一致）
if [ -f "${SRC}/progress.md" ]; then
  perl -i -pe 's/^status: active$/status: done/' "${SRC}/progress.md" || true
fi

cd "$ROOT"
if [ -d "$DEST" ]; then
  # archive 下已有同名（之前归过任务）→ 合并：把活跃项目的内容搬进去
  echo "ℹ️ archive/${PROJ} 已存在（曾归档过任务），合并整包进去"
  mkdir -p "${DEST}/tasks"
  [ -d "${SRC}/tasks" ] && rsync -a "${SRC}/tasks/" "${DEST}/tasks/" && rm -rf "${SRC}/tasks"
  rsync -a "${SRC}/" "${DEST}/"
  rm -rf "$SRC"
else
  mv "$SRC" "$DEST"
fi

# codes.md：把该项目状态改 done，路径指向 archive/
CODES="${ROOT}/assets/codes.md"
if [ -f "$CODES" ]; then
  PCODE="${PROJ%%-*}"
  python3 - "$CODES" "$PCODE" "$PROJ" "$TODAY" <<'PY'
import sys, pathlib, re
path, pcode, proj, today = sys.argv[1:]
p = pathlib.Path(path); text = p.read_text()
def repl(m):
    return f"| {pcode} | {proj.split('-',1)[1]} | `archive/{proj}/` | done（{today} 归档） |"
text = re.sub(rf"\| {pcode} \|[^\n]*\|", repl, text, count=1)
p.write_text(text)
PY
fi

# 顶层 progress.md「最近完成」加一行
TOP_PROG="${ROOT}/progress.md"
if [ -f "$TOP_PROG" ]; then
  python3 - "$TOP_PROG" "$TODAY" "$PROJ" <<'PY'
import sys, pathlib
path, today, proj = sys.argv[1:]
p = pathlib.Path(path); text = p.read_text()
marker = "## 最近完成"
line = f"- {today} [项目归档 {proj}](archive/{proj}/progress.md)"
if marker in text:
    head, _, tail = text.partition(marker)
    tl = tail.split("\n")
    p.write_text(head + marker + "\n".join([tl[0], "", line] + [l for l in tl[1:] if l.strip() != "_暂无_"]))
else:
    p.write_text(text + f"\n\n{marker}\n\n{line}\n")
PY
fi

git add -A
git commit -m "[${PROJ%%-*}] 项目归档 → archive/${PROJ}" --quiet
echo "✅ 项目已归档: projects/${PROJ} → archive/${PROJ}"
