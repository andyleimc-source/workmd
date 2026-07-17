---
name: inbox-triage
description: 清理 inbox/ 草稿区——逐条判断该升格为 task/project、并入现有项目、归档还是丢弃，按命名规范给出建议并（经确认后）调 new-task.sh / new-project.sh。用户输入 /inbox-triage 触发。
disable-model-invocation: true
---

# Inbox 归类

把 `inbox/` 里的临时草稿分流到正确归宿。**建文件夹前必须用户确认**（CLAUDE.md：AI 永远不要自动建任务）。

## 步骤

1. 列出 `inbox/` 下所有非 `.gitkeep` 文件，Read 每个内容
2. 读 `assets/codes.md` 了解现有 P/T 编号和下一个可用号；读顶层 `progress.md` 了解在做什么
3. 对每条草稿判定归宿（给理由，一句话）：
   - **并入现有项目** → 建议 `./scripts/new-task.sh <slug> P0X`
   - **零散小事** → `./scripts/new-task.sh <slug>`（默认落 `P00-misc`）
   - **升格项目**（多步/跨周）→ `./scripts/new-project.sh <slug>`，**并问用户确认**
   - **并入现有任务/文档** → 指出目标文件，建议追加
   - **丢弃** → 说明为什么没价值
4. 把判定结果做成一张表给用户过目
5. **用户逐条确认后**才执行：跑脚本建文件夹、把草稿内容迁入对应 progress.md、从 inbox 删除原草稿
6. 完成后 `git add -A && git commit`

## 输出（先给清单，等确认）

```
## Inbox 归类建议（N 条）

| 草稿 | 摘要 | 建议归宿 | 命令/动作 |
|------|------|----------|-----------|
| xxx.md | ... | 升格 P01 任务 | ./scripts/new-task.sh slug P01-... |

确认要执行哪几条？（可说「全做」/「只做 1、3」/「都先别动」）
```

要点：命名严格走 `T0X-YYYY-MM-DD-slug` / `P0X-slug`；编号一律由脚本分配，别手编;不确定归属就问，别硬塞。
