#!/usr/bin/env bash
# worker-do.sh <卡号> — 司机派工：施工 agent 在隔离 worktree 里按任务卡施工
#
#   scripts/worker-do.sh W01
#
# 流程：建 worktree（分支 task/<卡>）→ 施工方非交互模式按卡干活（git 作者硬标记）
#       → 打印验收摘要给司机。日志落 .worktrees/<卡>/.worker.log
#
# 卡片两种来源（自动识别）：
#   ① KB 维护卡：worker-cards/<卡号>*.md（改知识库本身）
#   ② 项目施工卡：projects/*/tasks/<卡号>-*/progress.md（改项目内代码/内容，卡号 T##）
#
# 施工方 CLI 可换：export WORKER_CLI=<任何支持 -p "<prompt>" 非交互模式的 AI CLI>
# 默认 agy（Google Antigravity CLI）。
set -euo pipefail

TASK="${1:-}"
[[ -n "$TASK" ]] || { echo "用法: scripts/worker-do.sh <卡号>  (W## 走 worker-cards/，T## 走 projects/*/tasks/)"; exit 1; }

WORKER_CLI="${WORKER_CLI:-agy}"
WORKER_NAME="${WORKER_NAME:-$WORKER_CLI}"
command -v "$WORKER_CLI" >/dev/null 2>&1 || {
  echo "❌ 找不到施工方 CLI: $WORKER_CLI"
  echo "   装一个能非交互跑的 AI CLI，或 export WORKER_CLI=<你的 CLI>"
  exit 1
}

MAIN="$(git worktree list --porcelain | head -1 | sed 's/^worktree //')"
cd "$MAIN"
WT=".worktrees/$TASK"
BASE="$(git symbolic-ref --short HEAD)"

# 1) 建/复用 worktree（复用=返工重跑，先同步主分支拿返工单）
if [[ -d "$WT" ]]; then
  echo "→ 复用已存在的 worktree $WT（返工重跑），先合并 $BASE"
  git -C "$WT" merge --no-edit -q "$BASE" || { echo "❌ 合并有冲突，手动解决后重跑"; exit 1; }
else
  echo "→ 建 worktree $WT（分支 task/$TASK）"
  git worktree add -q -b "task/$TASK" "$WT" "$BASE" 2>/dev/null || git worktree add -q "$WT" "task/$TASK"
fi

# 2) 定位任务卡：先找 worker-cards/（KB 卡），再找 projects/*/tasks/（项目施工卡）
CARD="$(cd "$WT" && { ls worker-cards/${TASK}-*.md worker-cards/${TASK}.md 2>/dev/null; ls projects/*/tasks/${TASK}-*/progress.md 2>/dev/null; } | head -1 || true)"
[[ -n "$CARD" ]] || { echo "❌ 找不到 ${TASK} 的卡（worker-cards/${TASK}*.md 或 projects/*/tasks/${TASK}-*/progress.md）；先建卡并 commit 到主分支再跑"; exit 1; }
echo "→ 任务卡：$CARD"

# 3) 施工指令（让施工方自己读文件，省司机 token）
read -r -d '' PROMPT <<EOF || true
你是本项目的施工 agent。当前目录是任务 ${TASK} 的隔离 worktree（分支 task/${TASK}）。按顺序：
1. 完整读 ./WORKER.md —— 你的施工须知与铁律（文件禁区、拿不准写回执、自检、commit 规范）。
2. 完整读 ./${CARD} —— 任务卡，你的唯一契约。严格照它，别自由发挥。
3. 只改任务卡「文件归属」允许的文件。真相源/协作文档/assets/codes.md/scripts/凭据文件一律不碰。
4. 完成前自检（见 WORKER.md 铁律 4，按改动类型）：改脚本 → \`bash -n\` 过；改 frontmatter → YAML 合法字段齐；卡里指定了额外自检命令就逐条跑。
5. 自检过 → 按 WORKER.md 规范 commit（带 Co-Authored-By: ${WORKER_NAME} 署名）。有歧义/没做完/涉及编号或凭据变动 → 别猜，在 ./${CARD} 末尾追加「## 施工回执」写清楚，然后停。
6. 最后只打印一段简短总结：改了哪些文件、自检结果、有没有回执。
EOF

# 4) （agy 专用）信任 worktree 目录
#    worktree 是新绝对路径，不在 agy 的 trustedWorkspaces 里就秒超时零输出。
#    --dangerously-skip-permissions 只跳工具权限、不跳文件夹信任，必须自己幂等注入。
#    换成别的 CLI 时这段自动跳过。
if [[ "$WORKER_CLI" == "agy" ]]; then
  WT_ABS="$MAIN/$WT"
  AGY_SETTINGS="$HOME/.gemini/antigravity-cli/settings.json"
  if [[ -f "$AGY_SETTINGS" ]]; then
    python3 - "$AGY_SETTINGS" "$WT_ABS" <<'PY' 2>/dev/null || true
import json, sys
path, wt = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(path))
except Exception:
    sys.exit(0)
tw = d.setdefault("trustedWorkspaces", [])
if wt not in tw:
    tw.append(wt)
    json.dump(d, open(path, "w"), indent=2, ensure_ascii=False)
    print("  → 已信任 worktree:", wt)
PY
  fi
fi

# 5) 跑施工方
#    GIT_AUTHOR_* = 硬标记：commit 作者即施工方，审查时 git log --author 一查全出。
WORKER_ARGS="${WORKER_ARGS:---dangerously-skip-permissions --print-timeout 30m}"
echo "→ 启动施工（$WORKER_CLI）…日志：$WT/.worker.log"
set +e
( cd "$WT" && GIT_AUTHOR_NAME="$WORKER_NAME" GIT_AUTHOR_EMAIL="${WORKER_NAME}@worker" \
    "$WORKER_CLI" $WORKER_ARGS -p "$PROMPT" ) 2>&1 | tee "$WT/.worker.log"
RC=${PIPESTATUS[0]}
set -e

# 6) 验收摘要
echo ""
echo "══════════ 施工结束（rc=$RC）· 验收摘要 ══════════"
echo "— 分支 task/$TASK 相对 $BASE 的改动："
git -C "$WT" --no-pager diff --stat "$BASE" || true
echo "— 最近 commit："
git -C "$WT" --no-pager log --oneline -3 || true
echo "— 是否有施工回执："
grep -q "## 施工回执" "$WT/$CARD" && echo "  ⚠ 有回执，看 $WT/$CARD 末尾" || echo "  无（施工方认为做完了）"
echo "═══════════════════════════════════════════════"
echo "下一步（司机）：审 diff → 过则合并（git merge task/$TASK && git worktree remove $WT）；不过则在卡尾写返工单重跑本脚本。"
