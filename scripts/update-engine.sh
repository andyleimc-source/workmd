#!/usr/bin/env bash
# update-engine.sh [--apply] [--with-rules] [--force]
# 从上游拉取「引擎」的更新（脚本、agent/skill、模板、文档），**绝不碰你的工作内容**。
#
#   ./scripts/update-engine.sh                        # 只看会改什么（dry-run，默认）
#   ./scripts/update-engine.sh --apply                # 真的更新
#   ./scripts/update-engine.sh --apply --with-rules   # 连 CLAUDE.md（规则正本）一起更新
#   ./scripts/update-engine.sh --apply --force        # 你改过引擎文件、确认可丢弃时
#
# 绝不触碰：projects/ archive/ inbox/ assets/codes.md 各种 progress.md/plan.md/
#           decision.md/bug.md/handoff.md/.claude/settings.json/.mcp.json
#
# 为什么不直接 git pull：你的 progress.md / codes.md / projects/ 是你自己的内容，
# 上游那几个是空模板。直接 pull 会在这些文件上撞出冲突，非常烦。本脚本只挑引擎文件。
set -euo pipefail

UPSTREAM_URL="https://github.com/andyleimc-source/workmd.git"

# ── 自我保护：本脚本就在 scripts/ 下，更新时会覆盖正在运行的自己。
# bash 是边读边执行的，覆盖后半段会读到错乱内容（真实的坑，不是理论风险）。
# 所以先把自己复制到临时目录再从那儿跑，让 git 随便覆盖原文件。
if [ "${_ENGINE_RELAUNCHED:-}" != "1" ]; then
  _ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  _TMP_SELF="$(mktemp -t workmd-update-engine.XXXXXX)"
  cp "$0" "$_TMP_SELF"
  chmod +x "$_TMP_SELF"
  export _ENGINE_RELAUNCHED=1 _ENGINE_ROOT="$_ROOT"
  "$_TMP_SELF" "$@"
  rc=$?
  rm -f "$_TMP_SELF"
  exit $rc
fi

ROOT="${_ENGINE_ROOT}"
cd "$ROOT"

APPLY=0
WITH_RULES=0
FORCE=0
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    --with-rules) WITH_RULES=1 ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    # ${a} 的花括号不能省：写成 "$a（…" 时 bash 在 UTF-8 下会把中文括号
    # 一并当成变量名，去找不存在的 ${a（用法见} → set -u 直接崩成乱码（踩过）。
    *) echo "❌ 不认识的参数: ${a}（用法见 --help）" >&2; exit 1 ;;
  esac
done

# ── 引擎文件：上游维护，你不该改，可以安全覆盖
ENGINE_PATHS=(
  scripts
  .claude/agents
  .claude/skills
  extras
  assets/templates
  README.md
  INSTALL.md
  AGENTS.md
)
# ── 你的东西：本脚本永不触碰
#    projects/ archive/ inbox/ assets/codes.md assets/docs assets/refs assets/snippets
#    progress.md plan.md decision.md bug.md handoff.md .claude/settings.json .mcp.json
# ── 灰区：CLAUDE.md 是规则正本，你可能按自己习惯改过 → 只有 --with-rules 才更新
[ "$WITH_RULES" = "1" ] && ENGINE_PATHS+=(CLAUDE.md)

# ── 接上上游
if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "→ 没有 upstream remote，自动加上：$UPSTREAM_URL"
  git remote add upstream "$UPSTREAM_URL"
fi
echo "→ 拉取上游…"
git fetch -q upstream main || { echo "❌ 拉不到上游（检查网络）" >&2; exit 1; }

# ── 算差异
# 注意方向：写 `git diff HEAD upstream/main` 而不是 `git diff upstream/main`。
# 后者算的是「从上游到我」，+/- 号会整个反过来（上游新增的行显示成删除），
# 而这个 dry-run 正是用户用来决定要不要更新的画面，反了就是误导。
CHANGED="$(git diff --name-only HEAD upstream/main -- "${ENGINE_PATHS[@]}" 2>/dev/null || true)"

# CLAUDE.md 是灰区：不带 --with-rules 时不动它，但要提一句它与上游有差异。
rules_differ() {
  [ "$WITH_RULES" = "0" ] && ! git diff --quiet HEAD upstream/main -- CLAUDE.md 2>/dev/null
}

if [ -z "$CHANGED" ]; then
  echo "✅ 引擎已是最新，没有要更新的。"
  rules_differ && echo "ℹ️  注：CLAUDE.md（规则正本）与上游有差异。若你没自己改过规则，可跑 --apply --with-rules 一并更新。"
  exit 0
fi

echo ""
echo "══════ 引擎有更新 ══════"
git diff --stat HEAD upstream/main -- "${ENGINE_PATHS[@]}"
echo "════════════════════════"

if [ "$APPLY" = "0" ]; then
  echo ""
  echo "以上是 dry-run（没动任何文件）。确认无误后跑："
  echo "   ./scripts/update-engine.sh --apply"
  rules_differ && echo "ℹ️  CLAUDE.md（规则正本）也与上游有差异，但默认不动它（怕覆盖你改过的规则）。要一起更新加 --with-rules。"
  exit 0
fi

# ── 应用前：找出「你自己改过的引擎文件」，别拿上游版本静默盖掉。
#
# 判据必须是「你相对上游改了什么」，不能是「工作区脏不脏」（原来就是这么写的，完全失效）：
# 本系统的 SessionEnd hook 会自动 commit 一切 —— 用户的定制在一个会话内必然被提交，
# 之后 git status 就是干净的，防线永远不触发，定制被静默铲掉。踩过，且是最严重的一次。
#
# 正确算法：共同祖先(merge-base) → HEAD 之间对引擎文件的改动 = 你的自定义。
# 再并上未提交的改动。其中「内容已等于上游」的排除掉（引导路径捞脚本会留下这种，
# 覆盖它不损失任何东西）。
BASE="$(git merge-base HEAD upstream/main 2>/dev/null || true)"

if [ -z "$BASE" ]; then
  # 与上游无共同祖先：多半是跑过 rm -rf .git && git init（老版 README 教的）。
  # 这种情况分不清「你的定制」和「单纯版本旧」，只能如实说，交给用户拍板。
  echo "⚠️  你的 git 历史与上游没有共同祖先（多半跑过 rm -rf .git）。" >&2
  echo "   这种情况我分不出哪些引擎文件是你自己改的、哪些只是版本旧，" >&2
  echo "   所以无法保证不覆盖你对引擎文件的定制。" >&2
  echo "   你的 projects/ archive/ 和各 progress.md 不受影响（本脚本从不碰它们）。" >&2
  echo "   确认要用上游版本覆盖引擎文件，加 --force 重跑：" >&2
  echo "      ./scripts/update-engine.sh --apply --force" >&2
  [ "$FORCE" = "1" ] || exit 1
  echo "→ --force 已指定，继续。"
fi

RISKY=""
CUSTOM="$( { [ -n "$BASE" ] && git diff --name-only "$BASE" HEAD -- "${ENGINE_PATHS[@]}" 2>/dev/null || true
             git status --porcelain -- "${ENGINE_PATHS[@]}" 2>/dev/null | sed 's/^...//' | sed 's/.* -> //'
           } | sort -u )"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  # 该文件当前内容已等于上游 → 是更新的一部分，不是你的活，无风险
  git diff --quiet upstream/main -- "$f" 2>/dev/null && continue
  RISKY="${RISKY}   ${f}"$'\n'
done <<< "$CUSTOM"

if [ -n "$RISKY" ] && [ "$FORCE" = "0" ]; then
  echo "⚠️  下列引擎文件你自己改过，更新会用上游版本覆盖它们：" >&2
  printf '%s' "$RISKY" >&2
  echo "" >&2
  echo "   想留住你的改动：先备份出去（cp 到别处），更新后再手动并回来。" >&2
  echo "   确认可以丢弃这些改动：./scripts/update-engine.sh --apply --force" >&2
  exit 1
fi

echo "→ 应用更新…"
git checkout upstream/main -- "${ENGINE_PATHS[@]}"
chmod +x scripts/*.sh scripts/hooks/*.sh 2>/dev/null || true
[ -d extras/driver-builder/scripts ] && chmod +x extras/driver-builder/scripts/*.sh 2>/dev/null || true

if git diff --cached --quiet && git diff --quiet; then
  echo "✅ 文件已是最新，无需 commit。"
  exit 0
fi

git add -A -- "${ENGINE_PATHS[@]}"
UP_SHA="$(git rev-parse --short upstream/main)"
if git config user.name >/dev/null 2>&1 && git config user.email >/dev/null 2>&1; then
  git commit -q -m "[engine] 从上游更新引擎 → ${UP_SHA}"
  echo "✅ 引擎已更新到上游 ${UP_SHA}，已 commit。"
else
  echo "✅ 引擎已更新到上游 ${UP_SHA}（已暂存）。"
  echo "   git 身份没配，没法自动 commit。配好后自己 commit 一下："
  echo "   git config --global user.name \"你的名字\""
  echo "   git config --global user.email \"你的邮箱\""
fi
echo "   你的 projects/ archive/ 和各 progress.md 一律没动过。"
