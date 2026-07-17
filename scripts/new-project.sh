#!/usr/bin/env bash
# new-project.sh <slug>
# 自动分配 P0X 编号，建 projects/P0X-<slug>/，登记到 assets/codes.md
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <slug>" >&2
  echo "  e.g. $0 website-redesign" >&2
  exit 1
fi

SLUG="$1"
DATE="$(date +%Y-%m-%d)"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODES="${ROOT}/assets/codes.md"

# 找下一个 P 编号：取 codes.md 与 projects/、archive/ 中出现过的最大编号 +1
# （编号只增不复用，归档的也算）
MAX=0
for n in $( { ls "${ROOT}/projects" 2>/dev/null | grep -oE '^P[0-9]+' ; ls "${ROOT}/archive" 2>/dev/null | grep -oE '^P[0-9]+' ; grep -E '^\|' "$CODES" 2>/dev/null | grep -oE 'P[0-9]+' ; } | tr -d 'P' ); do
  n=$((10#$n))
  [ "$n" -gt "$MAX" ] && MAX=$n
done
CODE=$(printf "P%02d" "$((MAX+1))")

PROJ_NAME="${CODE}-${SLUG}"
PROJ_DIR="${ROOT}/projects/${PROJ_NAME}"

if [ -d "$PROJ_DIR" ]; then
  echo "❌ project already exists: $PROJ_DIR" >&2
  exit 1
fi

mkdir -p "${PROJ_DIR}/tasks"

cat > "${PROJ_DIR}/progress.md" <<EOF
---
type: project
code: ${CODE}
slug: ${SLUG}
status: active
created: ${DATE}
---

# ${CODE} — ${SLUG}

## 项目目标

（一句话写清这个项目要交付什么）

## 下属任务

_新建任务用：./scripts/new-task.sh <task-slug> ${PROJ_NAME}_

## 进度

### ${DATE}

- 项目创建
EOF

cat > "${PROJ_DIR}/plan.md" <<EOF
# ${CODE} ${SLUG} — Plan

## 目标

## 阶段

## 风险
EOF

# 登记到 codes.md（追加到「## 项目」表，并更新「下一个可用」）
if [ -f "$CODES" ]; then
  python3 - "$CODES" "$CODE" "$SLUG" <<'PY'
import sys, pathlib, re
path, code, slug = sys.argv[1:]
p = pathlib.Path(path)
text = p.read_text()
row = f"| {code} | {slug} | `projects/{code}-{slug}/` | active |"
m = re.search(r"(## 项目[^\n]*\n\n\|.*?\|\n\|[-\| ]+\|\n(?:\|.*?\|\n)*)", text)
if m:
    block = m.group(1)
    text = text.replace(block, block.rstrip("\n") + "\n" + row + "\n")
else:
    print(f"⚠ codes.md 未找到「## 项目」表，请手动补登：{row}", file=sys.stderr)
nxt = f"P{int(code[1:]) + 1:02d}"
text = re.sub(r"(下一个可用：\*\*)P\d+(\*\*)", rf"\g<1>{nxt}\g<2>", text)
p.write_text(text)
PY
fi

cd "$ROOT"
git add "${PROJ_DIR}/progress.md" "${PROJ_DIR}/plan.md" "$CODES" 2>/dev/null || true
echo "✅ created: projects/${PROJ_NAME}/  [${CODE}]"
echo "   新建任务：./scripts/new-task.sh <task-slug> ${CODE}"
