#!/usr/bin/env bash
# audit-evidence.sh
# 抓「虚标」——已归档=当完成了、但「交付证据」还是占位没填的任务。
# 借鉴 SAGE「代码是事实，Issue 是线索」→ 本系统版「产出是事实，progress.md 是线索」。
# 只读、无副作用。只看带了「交付证据」小节的任务（新模板建的）；
# 更早、没这小节的老任务无法追溯，跳过不误报。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 0

found=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  # 有「## 交付证据」小节，但占位说明还在 → 归档时既没填也没删 → 落地存疑
  if grep -qF "## 交付证据" "$f" && grep -qF "有对外产出" "$f"; then
    echo "⚠ 交付证据未处理：${f#"$ROOT/"}"
    found=$((found+1))
  fi
done < <(ls archive/*/tasks/*/progress.md 2>/dev/null)

echo
if [ "$found" = "0" ]; then
  echo "✅ 没抓到虚标：已归档任务的交付证据都已填或已删占位。"
else
  echo "── 共 $found 个：归档时「交付证据」还是占位。逐个确认——真落地了就补证据，纯内部就删占位。"
fi
