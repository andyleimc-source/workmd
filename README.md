# workmd

**用纯 markdown + git 管理你的全部工作。人能读,AI 能写,没有数据库、没有 API、没有私有格式。**

一个项目一个文件夹,一个任务一个文件夹,一个 `progress.md` 记录发生了什么。仅此而已——但它跑了一年多,扛住了二十多个真实项目、四十多个任务,没散架。

```bash
git clone https://github.com/andyleimc-source/workmd.git
cd workmd && git remote rename origin upstream
```
然后跟你的 AI 说一句:「**读 INSTALL.md,帮我装一下**」。

> `git remote rename origin upstream` 是为了**保住上游**——以后修了 bug,你一句 `./scripts/update-engine.sh --apply` 就能拿到,不用重新克隆。这个脚本只更新引擎(脚本/agent/模板/文档),**绝不碰你的 `projects/`、`archive/` 和各种 `progress.md`**。
>
> 想把自己的库备份到私有仓库:`git remote add origin <你的仓库地址> && git push -u origin main`。上游和你的备份互不干扰。

---

## 为什么不用 Notion / Jira / 待办 App

因为**它们的数据不在你手上,而 AI 需要读到全部上下文才有用**。

当你的工作躺在纯 markdown 文件里:
- AI 一句 `grep` 就能横扫你所有项目,不用调 API、不用授权、不用等同步
- 你能用任何编辑器(Obsidian / VS Code / vim)打开,十年后还能打开
- git 天然给你版本历史、多设备同步、和"谁在什么时候改了什么"
- 没有订阅费,没有厂商跑路风险

代价是没有花哨的看板和甘特图。**这套东西赌的是:对知识工作者来说,「AI 能完整读懂你在干什么」比「漂亮的进度条」值钱得多。**

---

## 三分钟搞懂心智模型

### 1. 一切皆项目

```
projects/P03-website-redesign/          ← 项目
├── progress.md                         ← 项目进度（汇总，不写细节）
├── plan.md
└── tasks/
    └── T12-2026-06-26-hero-copy/       ← 任务
        └── progress.md                 ← 细节都在这
archive/P03-website-redesign/           ← 归档镜像同样的结构
└── tasks/T09-2026-06-01-.../
```

**任务只能挂在项目下,没有游离任务。** 那"顺手买个显示器"这种一次性小事呢?挂常驻兜底项目 `P00-misc`——它永不归档,就是杂事的家。

> 为什么这么死板:一旦允许游离任务,半年后你会有 200 个躺在顶层、彼此无关、想不起来为什么建的文件夹。**强制归属逼你在建的那一刻回答"这属于什么",这个动作本身就是整理。**

### 2. 编号只增不复用

`P03`、`T12` 全局递增,归档了、废弃了,号也不还回来。代价是号会跳(你可能从 T12 直接跳到 T15),好处是 **`T12` 永远只指过一件事**——搜索、回溯、口头说「把 T12 那个做完」全都无歧义。

编号由脚本分配并登记进 `assets/codes.md`,**人和 AI 都不许手编**。

### 3. 三层 progress,各管各的粒度

| 层 | 写什么 | 不写什么 |
|---|---|---|
| 顶层 `progress.md` | 索引:现在有什么在跑 | 任何细节 |
| 项目 `progress.md` | 下属任务的状态汇总 | 任务内的细节 |
| 任务 `progress.md` | 做了什么 / 下一步 | — |

顶层是**索引不是日志**。一眼扫完知道"现在有什么在跑",想看细节点链接进去。

### 4. 五件套落盘

`progress.md`(做了什么)· `plan.md`(要做什么)· `decision.md`(**为什么这么定**)· `bug.md`(已知的坑)· `handoff.md`(下次从哪接)

跟 AI 说一句「88」或「收工」,它就把本轮对话的关键信息落进对应文件然后 commit。

**标准是"三个月后失忆的我能不能凭这些 md 接上",不是流水账。** 尤其 `decision.md`——做了什么能从 git log 看出来,**为什么这么做只能看这里**。

---

## 这套东西真正的设计核心

**AI 永远不自动建任务、不自动建项目、不自动归档。**

它会提醒你(「这看起来是个任务,要挂哪个项目?」/「这三个项目 21 天没动静了,收尾了吗?」),但**动手前一定等你点头**。

这条看着像自缚手脚,其实是整套系统能活下来的唯一原因:

- 一个会自动建文件夹的 AI,能在两周内把你的知识库塞满没人认领的空壳
- 一个会自动归档的系统,等于一个会偷偷藏你东西的系统
- **人手动确认的那一秒钟,就是"这件事值不值得被记住"的过滤器**

工具的价值不在于替你做决定,在于让你的决定留下痕迹。

---

## 内置了什么

| 东西 | 是什么 |
|------|--------|
| `scripts/new-task.sh` / `new-project.sh` | 建新的,自动分配编号 + 登记注册表 + 填 frontmatter |
| `scripts/finish-task.sh` / `finish-project.sh` | 归档到 `archive/` 镜像位置,改 status,更新索引,commit(finish-task 带交付证据硬门) |
| `scripts/detect-done-projects.sh` | 只读体检:找出「21 天没提交 且 没有进行中任务」的项目 |
| `scripts/lessons.sh <关键词\|P0X>` | 开工前把该域已踩过的坑从文档里顶出来,别靠 AI 临场回忆 |
| `scripts/audit-evidence.sh` | 只读体检:抓已归档但「交付证据」没填的「虚标」 |
| SessionStart hook | 每周至多一次,把上面的候选注入 AI 上下文,让它挑个不打断你的时机问一句 |
| SessionEnd hook | 会话结束自动打 `[auto]` 快照 commit(安全网,不 push) |
| `scripts/update-engine.sh` | 从上游拉引擎更新(脚本/agent/模板/文档),**只碰引擎不碰你的内容**;默认 dry-run |
| `/inbox-triage` skill | 清 `inbox/` 草稿,逐条判归宿,你确认后才动手 |
| `archive-auditor` agent | 说「体检知识库」触发,扫出该归档没归档、frontmatter 不一致等问题。只读 |
| `CLAUDE.md` + `AGENTS.md` + `GEMINI.md` | **一份规则喂所有 AI CLI**:`CLAUDE.md` 是正本,`AGENTS.md` 是给别的 CLI 的薄壳,`GEMINI.md` 是软链 |

`extras/` 里还有可选加装件(默认不装):**driver-builder** 双 AI 分工套件(主力 AI 当司机派工 + 便宜 AI 在隔离 worktree 里施工 + git tag 水位线审查闭环),以及推荐的 skill/MCP 清单。

---

## 常用命令

```bash
./scripts/new-project.sh website-redesign        # 建项目 → P0X
./scripts/new-task.sh hero-copy P03              # 在 P03 下建任务 → T0X
./scripts/new-task.sh buy-monitor                # 省略项目 → 落 P00-misc
./scripts/finish-task.sh projects/P03-.../tasks/T12-...   # 归档任务
./scripts/finish-project.sh P03                  # 整包归档（确认后再跑）
./scripts/detect-done-projects.sh                # 只读体检
./scripts/update-engine.sh                       # 看上游有什么更新（dry-run）
./scripts/update-engine.sh --apply               # 拉上游修复，不碰你的内容
```

对 AI 说话就更简单了:「进行 P03」「T12 做完了,归档」「建个任务:改官网首页文案,挂 P03」。

---

## 依赖

`bash` · `git` · `python3` · `perl` — macOS 和多数 Linux 自带。外挂一个都不装也能跑。

---

## 更新日志

装了的人跑 `./scripts/update-engine.sh --apply` 就能拿到引擎更新(只碰脚本/模板/文档,不碰你的内容)。

### v1.0.0 — 2026-07-22

首个公开发布。骨架:一切皆项目、编号只增不复用、三层 `progress.md`、提醒不代劳的归档、引擎与内容分离的 `update-engine.sh`。这一版还带上:

- **交付证据 + 硬门** — 任务模板加「交付证据」小节;`finish-task.sh` 归档前会拦下占位没处理的任务(`--no-evidence` 放行纯内部任务)。定义「完成」= 有证据表明结果**在对方那边成立**,不是「我发出去了」。
- **教训固化 `lessons.sh`** — 开工前按 项目/关键词 把该域已踩过的坑(文档里 `⚠/坑/踩过/别再/禁止` 标记的行)顶到眼前,别靠 AI 临场回忆。
- **虚标审计 `audit-evidence.sh`** — 只读体检,抓已归档但「交付证据」没填的任务。
- **任务自动判断** — 任务按门槛(≥3 信号且归属清楚)可自动建、凡落盘必亮去向;项目这种重决策仍永远等你点头。

---

## 出身

抽象自作者用了一年多的私人知识库 `dailymd`(二十多个项目、四十多个任务的真实使用)。所有业务内容已剥离,留下的是骨架和踩过坑之后定下的规矩。

MIT License.

---

<sub>**English**: `workmd` is a plain-markdown, git-backed work management system designed to be read and written by both humans and AI agents. One folder per project, one folder per task, one `progress.md` each. No database, no API, no lock-in — just files an LLM can `grep`. Docs are in Chinese; the structure speaks for itself. Clone it and tell your AI to read `INSTALL.md`.</sub>
