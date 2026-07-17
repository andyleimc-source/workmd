# AGENTS.md — 非 Claude 的 AI CLI 在本项目的入口(薄壳)

> **单一真相源 = `./CLAUDE.md`**(项目规则正本:目录结构/命名/归档/落盘全在那)。本文件不复制内容,只定角色和差异。
> Gemini 系若只认 `GEMINI.md`,本仓库已把它 symlink 到本文件,内容一致。

## 第一步:完整读 `./CLAUDE.md`

项目定义(一切皆项目 / 任务挂项目下 / `P00-misc` 兜底 / `archive/` 镜像归档)、命名规范、落盘规则全在那里,以它为准。

## 忽略清单(Claude Code 专属机制,你执行不了,跳过即可)

读到这些时别假装能做:

- **Skill 工具**与各 skill(`/inbox-triage` 等)——你没有这套机制
- **子代理**(`archive-auditor` 等 Agent 委派)
- **SessionStart / SessionEnd hook**(归档提醒、自动快照 commit)——这些由 Claude Code 的 hook 系统触发,你跑不了。**这意味着你干完活要自己记得 commit**,没有安全网兜你。
- Claude 侧 **MCP 工具**(邮件、浏览器、云服务等,走 Claude 的凭证链)

## 照做清单(与 Claude 同一标准)

- 建新任务走 `scripts/new-task.sh <slug> [P0X]`;建项目走 `scripts/new-project.sh <slug>`。**别手动建目录、别自己编编号。**
- 任务只挂项目下,零散杂事挂 `P00-misc`
- 归档走 `scripts/finish-task.sh` / `finish-project.sh`(后者**只在用户明确确认收尾后**跑)
- **AI 永远不自动建任务、不自动建项目、不自动归档**——这是本系统的地基
- **commit**:改完直接 commit(push 手动);message 前缀用 `[T0X]`/`[P0X]`
- 不确定直说不确定,不要猜
- 建议在 commit 结尾署名,让人分得清哪些是你写的:
  ```
  Co-Authored-By: <你的名字> <noreply@agent>
  ```

## 可选加装件

若本仓库启用了 `extras/driver-builder/`(双 AI 分工套件),你可能被派为**施工方**:被 `worker-do.sh` 调起、当前目录在 `.worktrees/<卡号>/` 里 → **只看 `WORKER.md` + 你那张任务卡**,本文件其余部分与你无关。详见 `extras/README.md`。
