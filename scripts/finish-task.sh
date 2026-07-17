#!/usr/bin/env bash
# finish-task.sh <task-path>
# 归档单个任务到 archive/（镜像 projects/ 结构），更新 frontmatter，更新顶层 progress.md，git commit。
# 结构规矩：一切任务都在 projects/P0X-slug/tasks/ 下 → 归档到 archive/P0X-slug/tasks/。
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <task-path>" >&2
  echo "  e.g. $0 projects/P03-website-redesign/tasks/T12-2026-06-26-hero-copy" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_PATH="${1%/}"

# 前置检查：git 身份必须配好。
# 本脚本会先搬文件再 commit，等 commit 失败才发现就晚了——文件已经搬走、frontmatter 已改，
# 用户却以为归档失败。所以在动任何东西之前先验，快速失败。
cd "$ROOT"
if ! git config user.email >/dev/null 2>&1 || ! git config user.name >/dev/null 2>&1; then
  echo "❌ git 身份没配，归档会在最后 commit 时失败（而文件已经被搬走）。先跑：" >&2
  echo "   git config --global user.name \"你的名字\"" >&2
  echo "   git config --global user.email \"你的邮箱\"" >&2
  exit 1
fi

if [ ! -d "${ROOT}/${TASK_PATH}" ]; then
  echo "❌ not found: ${TASK_PATH}" >&2
  exit 1
fi

if [[ "$TASK_PATH" != projects/*/tasks/* ]]; then
  echo "❌ 任务必须在 projects/P0X-slug/tasks/ 下：${TASK_PATH}" >&2
  exit 1
fi

TASK_NAME="$(basename "$TASK_PATH")"
PROJECT_SLUG="$(echo "$TASK_PATH" | awk -F/ '{print $2}')"
TODAY="$(date +%Y-%m-%d)"

DEST_DIR="${ROOT}/archive/${PROJECT_SLUG}/tasks"
DEST_REL="archive/${PROJECT_SLUG}/tasks/${TASK_NAME}"

mkdir -p "$DEST_DIR"
if [ -d "${DEST_DIR}/${TASK_NAME}" ]; then
  echo "❌ destination already exists: ${DEST_REL}" >&2
  exit 1
fi

# 更新 frontmatter status → done（用 perl 而非 sed -i：BSD/GNU 语法不同，perl 跨平台一致）
PROG_FILE="${ROOT}/${TASK_PATH}/progress.md"
if [ -f "$PROG_FILE" ]; then
  perl -i -pe 's/^status: (in-progress|blocked)$/status: done/' "$PROG_FILE" || true
fi

cd "$ROOT"
git mv "$TASK_PATH" "$DEST_REL" 2>/dev/null || mv "$TASK_PATH" "$DEST_REL"

# 顶层 progress.md「最近完成」加一行
TOP_PROG="${ROOT}/progress.md"
if [ -f "$TOP_PROG" ]; then
  python3 - "$TOP_PROG" "$TODAY" "$TASK_NAME" "$DEST_REL" <<'PY'
import sys, pathlib
path, today, name, dest = sys.argv[1:]
p = pathlib.Path(path)
text = p.read_text()
marker = "## 最近完成"
line = f"- {today} [{name}]({dest}/progress.md)"
if marker in text:
    head, _, tail = text.partition(marker)
    tail_lines = tail.split("\n")
    new_tail = [tail_lines[0], "", line] + [l for l in tail_lines[1:] if l.strip() != "_暂无_"]
    p.write_text(head + marker + "\n".join(new_tail))
else:
    p.write_text(text + f"\n\n{marker}\n\n{line}\n")
PY
fi

git add -A
git commit -m "[${TASK_NAME}] archive → ${DEST_REL}" --quiet
echo "✅ archived: ${TASK_PATH} → ${DEST_REL}"
echo "   committed."
