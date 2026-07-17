#!/usr/bin/env bash
# new-task.sh <slug> [project]
# 自动分配 T0X 编号，建 projects/<P0X-slug>/tasks/T0X-YYYY-MM-DD-<slug>/，登记到 assets/codes.md
#
# 结构规矩：一切任务都挂项目下。不给 project 参数时默认落到常驻兜底项目 P00-misc。
# project 可以是 P01-xxx 完整名 / P01 编号 / 纯 slug（脚本会模糊匹配）
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <slug> [project]" >&2
  echo "  e.g. $0 fix-login-bug P03" >&2
  echo "       $0 buy-monitor          # 省略 project → 落到 P00-misc" >&2
  exit 1
fi

SLUG="$1"
PROJECT_IN="${2:-P00}"
DATE="$(date +%Y-%m-%d)"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="${ROOT}/assets/templates/task-progress-plain.md"
CODES="${ROOT}/assets/codes.md"

# 模糊匹配项目目录
if [ -d "${ROOT}/projects/${PROJECT_IN}" ]; then
  PROJECT_DIR="$PROJECT_IN"
else
  match=$(ls "${ROOT}/projects" 2>/dev/null | grep -E "^${PROJECT_IN}(-|$)|-${PROJECT_IN}$" || true)
  count=$(echo "$match" | grep -c . || true)
  if [ "$count" = "1" ]; then
    PROJECT_DIR="$match"
  elif [ "$count" = "0" ]; then
    echo "❌ project not found: $PROJECT_IN" >&2
    echo "   现有项目：" >&2
    ls "${ROOT}/projects" >&2
    exit 1
  else
    echo "❌ ambiguous project: $PROJECT_IN matches:" >&2
    echo "$match" >&2
    exit 1
  fi
fi

# 找下一个 T 编号：取 codes.md 与 projects/*/tasks/、archive/*/tasks/ 中出现过的最大编号 +1
# （编号只增不复用，归档的也算）
MAX=0
for n in $( { ls "${ROOT}"/projects/*/tasks 2>/dev/null ; ls "${ROOT}"/archive/*/tasks 2>/dev/null ; } | grep -oE '^T[0-9]+' ; grep -E '^\|' "$CODES" 2>/dev/null | grep -oE 'T[0-9]+' ); do
  n=$((10#${n#T}))
  [ "$n" -gt "$MAX" ] && MAX=$n
done
CODE=$(printf "T%02d" "$((MAX+1))")

TASK_DIR_NAME="${CODE}-${DATE}-${SLUG}"
TASK_PATH="${ROOT}/projects/${PROJECT_DIR}/tasks/${TASK_DIR_NAME}"
REL="projects/${PROJECT_DIR}/tasks/${TASK_DIR_NAME}"

if [ -d "$TASK_PATH" ]; then
  echo "❌ already exists: $TASK_PATH" >&2
  exit 1
fi

mkdir -p "${ROOT}/projects/${PROJECT_DIR}/tasks"
mkdir -p "$TASK_PATH"

# 渲染模板
sed -e "s/__CODE__/${CODE}/g" \
    -e "s/__SLUG__/${DATE}-${SLUG}/g" \
    -e "s|__PROJECT__|${PROJECT_DIR}|g" \
    -e "s/__DATE__/${DATE}/g" \
    "$TEMPLATE" > "${TASK_PATH}/progress.md"

# 登记 codes.md（追加到「## 任务」表，并更新「下一个可用」）
PROJ_CODE="${PROJECT_DIR%%-*}"
if [ -f "$CODES" ]; then
  python3 - "$CODES" "$CODE" "$SLUG" "$REL" "$PROJ_CODE" <<'PY'
import sys, pathlib, re
path, code, slug, rel, proj = sys.argv[1:]
p = pathlib.Path(path)
text = p.read_text()
row = f"| {code} | {slug} | `{rel}/` | {proj} | in-progress |"
m = re.search(r"(## 任务[^\n]*\n\n\|.*?\|\n\|[-\| ]+\|\n(?:\|.*?\|\n)*)", text)
if m:
    block = m.group(1)
    text = text.replace(block, block.rstrip("\n") + "\n" + row + "\n")
else:
    print(f"⚠ codes.md 未找到「## 任务」表，请手动补登：{row}", file=sys.stderr)
nxt = f"T{int(code[1:]) + 1:02d}"
text = re.sub(r"(下一个可用：\*\*P\d+\*\* / \*\*)T\d+(\*\*)", rf"\g<1>{nxt}\g<2>", text)
p.write_text(text)
PY
fi

cd "$ROOT"
git add "${TASK_PATH}/progress.md" "$CODES" 2>/dev/null || true
echo "✅ created: ${REL}/progress.md  [${CODE}]"
echo "   open: ${TASK_PATH}/progress.md"
