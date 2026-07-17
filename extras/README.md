# extras — 可选加装件

这里的东西**默认不启用**。核心系统(projects/tasks/archive/脚本/hooks)不依赖它们,克隆下来什么都不装也能正常用。

按需自取,或者让 AI 读 `INSTALL.md` 帮你装。

---

## 1. `driver-builder/` — 双 AI 分工套件

**解决什么问题**:你的主力 AI(比如 Claude Code)额度贵、上下文宝贵,但很多活是机械的(改一堆样板、批量整理、按规格施工)。这套东西让主力 AI 当**司机**只做判断和验收,把粗活派给一个更便宜的 AI(**施工方**)在隔离 worktree 里干。

**机制三件套**:

| 环节 | 做法 |
|------|------|
| **派工** | 司机在 `worker-cards/` 按模板建一张**自包含任务卡**(标准:另开一个全新会话的 agent 只读这张卡就能干完并通过验收)→ 跑 `worker-do.sh <卡号>` |
| **隔离** | 脚本自动建 git worktree(分支 `task/<卡号>`),施工方物理隔离,改坏了不影响主库 |
| **审查** | `worker-review.sh` 用 git tag 当**水位线**,列出水位线之后施工方干的所有 commit → 司机审 → `--pass` 挪水位线闭环 |

**关键设计**:
- 施工方的 commit 被**硬标记**作者(`GIT_AUTHOR_NAME`),`git log --author` 一查全出,跑不掉
- `WORKER.md` 里五条铁律,最狠的是**铁律 2「文件归属」**——施工方只能动任务卡明确允许的文件,协作文档/编号注册表/脚本一律禁碰(这些回主分支由司机改)。没有这条,并行施工会在合并期爆冲突。
- 拿不准就**停下写「施工回执」**,不许猜着做完

**依赖**:一个能非交互跑的 AI CLI(默认 `agy`,可用 `WORKER_CLI` 环境变量换成任何支持 `-p "<prompt>"` 的 CLI)。

**装法**:
```
cp extras/driver-builder/WORKER.md .
cp extras/driver-builder/scripts/worker-*.sh scripts/
cp -r extras/driver-builder/worker-cards .
git tag worker-reviewed        # 初始化审查水位线（当前起点即豁免历史）
```
然后在 `CLAUDE.md` 末尾加一句指向 `WORKER.md`,让司机知道有这套东西。

**不适合谁**:只有一个 AI、活也不重的人。这套的价值随「机械活占比」上升,活不重时纯属额外仪式。

---

## 2. `recommended.md` — 推荐的 skill / MCP 清单

外部依赖清单与装法。**全部可选**,一个不装系统照常跑。让 AI 读 `INSTALL.md` 会逐档问你要不要装。
