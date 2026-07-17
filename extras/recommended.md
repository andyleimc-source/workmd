# 推荐的 skill / MCP 清单

**全部可选。一个不装,系统照常跑。** 这些是原作者在自己的知识库里实际长期用着的外挂,按「和工作管理的相关度」排序。

安装时让 AI 读 `INSTALL.md`,它会逐档问你要不要装。也可以照下表自己手动装。

> ⚠️ **凭据一律你自己填,别让 AI 帮你编。** 下表凡是标「需凭据」的,装完都要你自己去对应平台拿 key/登录。

---

## 内置(已在仓库里,不用装)

| 名字 | 类型 | 干什么 |
|------|------|--------|
| `inbox-triage` | skill | `/inbox-triage` 清 `inbox/` 草稿,逐条判归宿,确认后调脚本建任务 |
| `archive-auditor` | agent | 说「体检知识库」时触发,扫出该归档没归档、frontmatter 不一致、codes.md 对不上等问题。只读 |
| 两个 hook | Claude Code hook | SessionStart 归档提醒(限频 7 天)、SessionEnd 自动快照 commit |

---

## A 档 · 和这套系统配合最紧的

### 浏览器自动化 — `claude-in-chrome`
Claude Code 官方扩展。查资料、抓页面、填表单落进任务里,是这套知识库最高频的外挂。
```
# Chrome 应用商店装 Claude for Chrome 扩展，然后在 Claude Code 里 /claude-in-chrome
```
不需要凭据,但每个站点要单独授权。

### 邮件 — `ms365` MCP(需凭据)
Microsoft 365 / Outlook 邮件读写。把邮件线索直接落进任务 `progress.md` 很顺手。
```
npm i -g ms-365-mcp-server
```
`.mcp.json` 配置见 `.mcp.json.example`。装完首次调用会走 OAuth 登录。

---

## B 档 · 通用办公

| 名字 | 装法 | 需凭据 | 干什么 |
|------|------|--------|--------|
| `google-workspace` MCP | 见其仓库 README | ✅ OAuth | 读写 Google Sheets / Docs / Drive |
| `google-analytics` MCP | `uvx --from google-analytics-mcp ga4-mcp-server` | ✅ service account json + property id | 拉 GA4 数据 |

---

## C 档 · 中文/国内平台

| 名字 | 来源 | 需凭据 | 干什么 |
|------|------|--------|--------|
| `hap-cli` | `mingdaocom/hap-skills` → `skills/cli/hap-cli/SKILL.md` | ✅ | HAP / 明道云主入口:通讯录、消息、动态、日程、工作表增删改查 |
| `hap-cli-data-query` | 同上 → `skills/cli/hap-cli-data-query/` | — | 复杂筛选 / 透视聚合的写法 |
| `hap-cli-app-editor` | 同上 → `skills/cli/hap-cli-app-editor/` | — | 改已有应用的字段/视图/工作流/权限 |
| `hap-cli-environments` | 同上 → `skills/cli/hap-cli-environments/` | — | 多环境/多账号时决定在哪跑(防误操作线上) |
| `wx-cli` | `jackwener/wx-cli` → `SKILL.md` | ✅ 本地微信库 | 查本地微信聊天记录、联系人、群成员 |
| `baoyu-post-to-wechat` | `JimLiu/baoyu-skills` | ✅ 公众号 API 或 Chrome CDP | 发布公众号文章/图文 |
| `baoyu-imagine` | `JimLiu/baoyu-skills` | ✅ 各家图像 API key | AI 生图(OpenAI / Google / DashScope / Replicate 等多家) |

装法(Claude Code skill 市场语法,以你的 CLI 版本为准):
```
/plugin marketplace add mingdaocom/hap-skills
/plugin marketplace add JimLiu/baoyu-skills
```
装完的版本锁记录在 `skills-lock.json`。

---

## D 档 · 设计类(和工作管理无关,纯锦上添花)

原作者装了一批前端/设计审美类 skill(`taste-skill`、`brandkit`、`redesign-skill`、`minimalist-skill` 等),用来做对外物料和网页。**这些和本系统没有任何耦合**,来源没有记录在本仓库里,想要自己搜。

Claude Code 自带的 `frontend-design`、`artifact-design`、`dataviz` 已经覆盖大部分场景,先用自带的。

---

## 关于 `.mcp.json`

`.mcp.json` 常含**本机凭据路径**,已加进 `.gitignore` **不进版本控制**。仓库里给的是 `.mcp.json.example` 模板:

```
cp .mcp.json.example .mcp.json
# 然后按注释填你自己的路径和 ID
```
