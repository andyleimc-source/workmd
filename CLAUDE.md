# workmd — 项目与任务知识库

这是一个纯 markdown 的个人工作管理系统:每个项目一个文件夹,每个任务一个文件夹,后端用 git 同步多台设备。人用编辑器读写,AI 直接读写同样的文件——**没有数据库、没有 API、没有私有格式**。

**本文件是规则正本(单一真相源)。** AI 在此目录工作时遵守以下全部规范。其他入口文件(`AGENTS.md` / `GEMINI.md`)只是薄壳,内容以本文件为准。

---

## 一、核心规矩:一切皆项目

> **任务只能挂在项目下,没有顶层 `tasks/`。** 连一次性的独立小事也必须落在某个项目里——零散杂事挂常驻兜底项目 `P00-misc`。

为什么:一旦允许"游离任务",半年后你会有 200 个躺在顶层、彼此无关、想不起来为什么建的文件夹。强制归属逼你在建的那一刻就回答"这属于什么",这个动作本身就是整理。

### 目录结构

- `projects/P0X-<slug>/` — **项目(唯一活跃根)**,含 `progress.md`、`plan.md`
- `projects/P0X-<slug>/tasks/T0X-<YYYY-MM-DD>-<slug>/` — 项目下的任务(必含 `progress.md`)
- `projects/P00-misc/tasks/…` — **常驻兜底项目**:不值得单开项目的零散一次性任务的家
- `archive/` — **唯一归档根,镜像 `projects/` 结构**:
  - `archive/P0X-<slug>/tasks/<task>/` — 项目仍活跃、但某个任务已完成 → 就近归到镜像位置
  - `archive/P0X-<slug>/` — 整个项目已收尾 → 整包搬进来
- `assets/codes.md` — **编号注册表(P/T 全局编号 → 路径)**
- `assets/templates/` — 新建任务/项目的纯文本模板(脚本填充)
- `assets/docs/` — SOP、规范、长期文档
- `assets/snippets/` — 代码片段、命令片段
- `assets/refs/` — 外部引用、联系人、截图等参考材料
- `inbox/` — 临时未归类草稿(用 `/inbox-triage` 定期清)
- `scripts/` — 项目内一行脚本(见下)
- `extras/` — 可选加装件(默认不启用,见 `extras/README.md`)

---

## 二、命名规范

- **项目文件夹**:`P0X-<kebab-slug>`(P 全局递增,**不复用**)
- **任务文件夹**:`T0X-<YYYY-MM-DD>-<kebab-slug>`(T 全局递增,**不复用**)
- **commit message**:`[T0X] 一句话` 或 `[P0X] 一句话`,复杂时可加 slug:`[T0X-blog-fix] 一句话`

**编号只增不复用**(归档的、删掉的都算数)。代价是号会跳,好处是 `T17` 永远只指过一件事——搜索、回溯、口头指代(「把 T17 那个做完」)全都无歧义。

用户在会话里可直接说「进行 P01」「做一下 T03」定位,AI 用 `assets/codes.md` 查表。

---

## 三、何时建任务 / 项目

### 建任务

- **AI 永远不要自动建。** 由用户显式说「建任务」或确认后才建。
- **任务必须挂在某个项目下。** 建时确定归属:属于某个现有项目就挂它;只是零散小事就挂 `P00-misc`。
- 当对话中识别到候选任务(明确目标 + 多步动作 + 跨会话可能),**主动问一句**:
  > 这看起来是个任务,要挂哪个项目下?(零散小事就放 `P00-misc`)slug 建议:`xxx`
- 用户同意后用 `scripts/new-task.sh <slug> <P0X 或项目目录名>` 创建;**不给第二个参数默认落到 `P00-misc`**。

### 建项目

- 出现两个以上互相关联的任务,或一个跨周/跨月推进的主题时,**问用户**是否升格为项目(把 `P00-misc` 里相关任务挪进新项目 `tasks/`)。
- 严肃独立任务想单开也行——先 `new-project.sh` 建项目,再在其下 `new-task.sh`。真只是杂事就别硬开项目,挂 `P00-misc`。

> **这条是整套系统的地基,不许放宽。** AI 自动建文件夹会让知识库在两周内长满没人认领的空壳;人手动确认的那一秒钟,就是"这件事值不值得被记住"的过滤器。

---

## 四、新建必走脚本

脚本自动分配编号、登记 `assets/codes.md`、填 frontmatter。**别手动建目录、别自己编编号。**

| 脚本 | 用途 |
|------|------|
| `./scripts/new-project.sh <slug>` | 分配下一个 P 号,建 `projects/P0X-<slug>/` |
| `./scripts/new-task.sh <slug> [P0X\|项目目录名]` | 分配下一个 T 号(第二参数支持模糊匹配,省略则落 `P00-misc`) |
| `./scripts/finish-task.sh <task-path>` | 归档单个任务到 `archive/` 镜像位置 |
| `./scripts/finish-project.sh <P0X>` | 整个项目收尾归档(**只在用户明确确认后跑**) |
| `./scripts/detect-done-projects.sh` | 只读体检:列出疑似做完忘归档的项目 |

---

## 五、任务 frontmatter

每个任务的 `progress.md` 顶部带 frontmatter(脚本自动填):

```yaml
---
type: task
code: T0X
slug: 2026-05-12-xxx
project: P0X-<project-slug>
status: in-progress  # in-progress | blocked | done
created: 2026-05-12
---
```

项目的 `progress.md` 同理,`type: project`、`status: active | done`。

这些字段用于 grep 检索和脚本聚合(`detect-done-projects.sh` 靠 `status` 判活)。**改文件时别破坏 frontmatter**,YAML 要合法、字段要齐。

---

## 六、进度管理:三层 progress

三个层级各管各的粒度,**不重复**:

- **任务级 `progress.md`** — 每次有实质进展追加一段 `## YYYY-MM-DD`,写「做了什么 / 下一步」。细节在这里。
- **项目级 `progress.md`** — 汇总下属任务状态(进行中 / 阻塞 / 已完成),**不重复任务内细节**。
- **顶层 `progress.md`** — 三段索引:
  - `## 进行中项目` — `projects/` 下每个项目一行
  - `## 进行中任务` — 各项目 `tasks/` 下进行中任务一行链接 + 一句话状态
  - `## 最近完成` — 最近 10 条归档记录,按日期倒序

顶层是**索引不是流水账**。判断标准:一眼扫完能知道"现在有什么在跑",想看细节点链接进去。

### Checkbox 约定

任务内待办用 `- [ ] 内容 📅 YYYY-MM-DD` 格式(日期 emoji 可选),各任务保持一致即可。

---

## 七、完成与归档

**单个任务完成**(项目还在推进):
1. 在任务 `progress.md` 末尾写 `## 完成 YYYY-MM-DD` 一句话总结
2. 跑 `scripts/finish-task.sh <task-path>`:自动 `mv` 到 `archive/P0X-slug/tasks/`(镜像位置)、frontmatter 改 `status: done`、更新顶层 `progress.md`、git commit

**整个项目收尾**:
1. 项目 `progress.md` 末尾写完成总结
2. 跑 `scripts/finish-project.sh <P0X>`:整包 `mv` 到 `archive/P0X-slug/`(若之前归过任务会自动合并)、`status: done`、更新 `codes.md` 与顶层 `progress.md`、git commit
3. **⚠ 只在用户明确确认「这个项目收尾了」后才跑,绝不自动归档。**

### 归档提醒机制(防止做完忘归档积压)

- SessionStart hook `scripts/hooks/session-start-archive-nudge.sh` 会调 `detect-done-projects.sh`,找「最后一次 git 提交 > 21 天前 **且** 没有进行中任务」的项目(用 git 提交日期判停滞,跨设备可靠;`P00-misc` 豁免)。
- 命中且距上次提醒 ≥ 7 天时,把候选注入上下文。**AI 收到后不要打断用户手头的事**,在对话自然告一段落时顺口问一句:这些项目是收尾了还是还在推进/卡住?
  - 确认收尾 → `scripts/finish-project.sh <P0X>`
  - 用户说「先别问 P0X」→ 往 `assets/.archive-nudge-snooze` 加一行 `P0X <一个月后的日期>`(该日期前不再提醒)
- 随时手动体检:`./scripts/detect-done-projects.sh`(只读,列候选)

> 设计要点:**提醒,但绝不代劳。** 一个会自动归档的系统等于一个会偷偷藏你东西的系统。

---

## 八、结束对话落盘

用户说 "bye" / "88" / "再见" / "收工" / "拜拜" 等 = **结束本轮对话**,触发落盘。

把本轮对话的重要信息写进**当前任务**的 `progress.md`(如果本轮没有具体任务,落到顶层 `progress.md`)。按需写,对应文件不存在就跳过,**不要新建**:

| 文件 | 写什么 |
|------|--------|
| `progress.md` | 本轮做了什么(追加一条带日期的简短条目) |
| `handoff.md` | 下次从哪开始 / 当前卡在哪 / 开放决策 |
| `decision.md` | 本轮做出的方向性决策 **+ 理由** |
| `bug.md` | 新发现但没修的 bug / 已知问题 |
| `plan.md` | 计划有变动才改 |

写完直接 `git commit`,无需再问。回复只说「已落盘」。

**标准是"未来的我能不能凭这些 md 接上",不是流水账。** 这五个文件是给三个月后失忆的你(和一个全新会话的 AI)看的。

---

## 九、Git

- 每次任务有实质进展或归档后直接 `git add -A && git commit`,不用问。message 用编号前缀:`[T12] 调通邮件模板`。
- **push 手动**(用户自己推),没有自动定时推送——防止和其他设备/会话撞车。
- SessionEnd hook 会在会话结束时对未提交改动打一个 `[auto] session-end snapshot` 快照,是安全网,不 push。

> 本项目故意用 `git add -A`(单人线性笔记库,一次任务改动本就是一件事)。如果你在通用代码项目里,不该这么干。

---

## 十、Assets 引用

任务内引用资产用相对路径:`../../../assets/docs/xxx.md`(任务都在 `projects/P0X/tasks/T0X/` 三层下)。

---

## 十一、可选加装件

`extras/` 下的东西**默认不启用**,按需自取,详见 `extras/README.md`:

- `extras/driver-builder/` — 双 AI 分工套件(司机派工 + 施工 agent 在隔离 worktree 里干活 + 审查闭环)
- `extras/recommended.md` — 推荐的 skill / MCP 清单与装法

---

## 十二、给 AI 的行为总纲

这套系统能用下去,靠的是几条反直觉的克制。按重要性排:

1. **不自动建任务、不自动建项目、不自动归档。** 提醒可以,代劳不行。
2. **不手编编号,一律走脚本。** 编号是全局契约,手编必错。
3. **顶层 progress 是索引不是日志。** 想往里塞细节时,塞进任务级。
4. **拿不准归属就问一句,别硬塞。** 塞错项目比放 `P00-misc` 更难修。
5. **落盘写"为什么",不写"做了啥"。** 三个月后的你能从 git log 看出做了啥,看不出为什么。
