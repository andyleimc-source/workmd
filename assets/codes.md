# 编号注册表 codes

P/T 全局编号 → 路径。**编号只增不复用**（归档的、废弃的都算数）。新建必走 `scripts/new-project.sh` / `scripts/new-task.sh`，脚本会自动往下面的表追加一行并更新「下一个可用」。

**结构规矩**：一切皆项目，任务只挂项目下（无顶层 `tasks/`）；零散一次性任务挂常驻 `P00-misc`。归档统一到唯一的 `archive/`，镜像 `projects/` 结构——已完成任务进 `archive/P0X-slug/tasks/`，整个收尾的项目整包进 `archive/P0X-slug/`。

下一个可用：**P01** / **T01**

## 项目 Projects

| 编号 | slug | 路径 | 状态 |
|------|------|------|------|
| P00 | misc | `projects/P00-misc/` | active（常驻杂事兜底） |

## 任务 Tasks

| 编号 | slug | 路径 | 项目 | 状态 |
|------|------|------|------|------|
