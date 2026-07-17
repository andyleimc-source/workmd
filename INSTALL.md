# INSTALL.md — 安装向导

> **这份文件主要是写给 AI 读的。**
> 人类:你不用读完。克隆下来跟你的 AI 说一句「**读 INSTALL.md,帮我装一下**」就行,它会逐档问你。
> 想手动装:跳到最后的「手动安装」。

---

## 给 AI:你的任务

用户刚克隆了 workmd,让你帮他装。**按下面顺序走,别跳步,别自作主张替他决定。**

### 原则(比步骤更重要)

1. **一次只问一档,等他答完再问下一档。** 别一口气甩四个问题,他会懵。
2. **默认答案是"不装"。** 每档都说清「这是干什么的 / 不装有什么损失」,让他能安心说不。装一堆用不上的东西比什么都不装更糟。
3. **凭据永远让他自己填。** 你不许猜、不许编、不许用示例值糊弄。要 key 就停下来让他去拿。
4. **装不上就跳过,别硬来。** 报一句「X 装失败,原因是 Y,先跳过,不影响主系统」然后继续。
5. **别在安装过程中建任何任务/项目。** 那是他自己的活。

---

### 第 0 步:先确认这是个新家

跑一下:

```bash
ls projects/ && cat assets/codes.md | grep "下一个可用"
```

- 如果 `projects/` 下只有 `P00-misc`、下一个可用是 `P01`/`T01` → 全新仓库,继续。
- 如果已经有别的项目 → **停下来问用户**:这是个已经在用的库,你是想重装还是只想补装某个外挂?别覆盖他的东西。

### 第 1 步:核心自检(不问,直接做)

```bash
bash -n scripts/*.sh scripts/hooks/*.sh && echo "✅ 脚本语法 OK"
python3 --version && perl -e 'print "✅ perl OK\n"'   # 脚本依赖这两个
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo "✅ 在 git 仓库里" || git init
```

**git 身份必须配好**,否则归档脚本会在最后 commit 时失败(而文件已经被搬走)。查一下,没配就**停下来问用户**要名字和邮箱,别替他编:
```bash
git config user.name && git config user.email || echo "⚠️ 没配，问用户要"
```

`GEMINI.md` 应该是指向 `AGENTS.md` 的软链接。检查一下,断了就重建:
```bash
[ -L GEMINI.md ] || ln -sf AGENTS.md GEMINI.md
```

**冒烟测试**——确认建/归档链路通。注意最后一步用 `git checkout` 复原,**别手动改 `assets/codes.md`**(手改极易让注册表和实际目录对不上,这是本系统最难查的一类问题):
```bash
git add -A && git commit -q -m "pre-smoke-test baseline"   # 先存个干净基线
./scripts/new-task.sh install-smoke-test                    # 应输出 [T01]
./scripts/detect-done-projects.sh; echo "（无输出=正常，新库没有停滞项目）"
rm -rf projects/P00-misc/tasks/T01-*-install-smoke-test      # 删测试任务
git checkout -- assets/codes.md                              # 注册表复原（关键：不要手改）
git reset --soft HEAD~1                                      # 撤掉基线 commit，回到克隆时的干净状态
```
跑完确认一下 `grep "下一个可用" assets/codes.md` 显示的是 `**P01** / **T01**`,是就告诉用户「链路通了,测试痕迹已清干净」。

### 第 2 步:改成他自己的库(问他)

问:

> 这个库是给你个人用还是团队共用?你主要拿它管什么?(一句话就行,我写进 `plan.md`)

拿到答案后:
- 把 `plan.md` 的「系统定位」填上他的话
- 把 `decision.md` 的 D1 填上(背景=他为什么需要、理由=他为什么选这套)
- **别动 `CLAUDE.md`**,除非他明确提出要改规则

### 第 3 步:逐档问外挂(核心环节)

**参照 `extras/recommended.md`。一档一问。**

先给他一句总述,再开始:

> 下面有几档可选外挂,**全都可以不装**,核心系统已经能用了。我一档一档问,你说不要就跳过。

#### 3.1 浏览器自动化(A 档)
> 要装 **claude-in-chrome** 吗?让 AI 能开你的 Chrome 查资料、抓页面、填表单,把结果直接落进任务里。这是这套库最高频的外挂。不需要 API key,但每个网站要你单独授权一次。

装:让他自己去 Chrome 商店装扩展,然后在 Claude Code 里跑 `/claude-in-chrome`。你无法代劳装扩展这一步,说清楚。

#### 3.2 邮件(A 档,需凭据)
> 要装 **ms365 邮件 MCP** 吗?能读写 Outlook/365 邮件,把邮件里的事直接变成任务。需要你的 365 账号 OAuth 登录一次。用 Gmail 的话这个没用,跳过。

装:
```bash
npm i -g ms-365-mcp-server
cp .mcp.json.example .mcp.json   # 若还没有
```
然后让他删掉 `.mcp.json` 里不要的条目。首次调用会弹 OAuth。

#### 3.3 国内平台(C 档)
> 你用 **HAP / 明道云** 吗?用的话可以装 hap-cli 系列(4 个 skill),AI 就能直接查改里面的表、发消息、看日程。需要你的 HAP 凭据。

装:
```
/plugin marketplace add mingdaocom/hap-skills
```
然后按 skill 自己的说明配凭据(**让他自己配**)。

单独再问一句:
> 要 **wx-cli**(查本地微信聊天记录)或 **baoyu-post-to-wechat**(发公众号)吗?

#### 3.4 双 AI 分工(可选加装件)
> 要装 **driver-builder** 吗?这是把机械活派给一个更便宜的 AI 去干、主力 AI 只做验收的套件。**前提是你手上有第二个能非交互跑的 AI CLI**(比如 agy)。没有的话跳过。

只有他明确说要,才照 `extras/README.md` 的装法做。**默认不装。**

#### 3.5 Google 系(B 档)
> 要装 google-workspace(读写 Sheets/Docs/Drive)或 google-analytics(拉 GA4)吗?两个都要你自己去 GCP 配凭据,比较麻烦,不确定就先跳过,以后随时能装。

### 第 4 步:收尾

```bash
git add -A && git commit -m "[init] 初始化 workmd 知识库 + 按需装外挂"
```

然后给他一段**不超过 8 行**的总结:
- 装了什么、跳过了什么
- **他下一步该干嘛**:`./scripts/new-project.sh <slug>` 建第一个项目,或者零散事直接 `./scripts/new-task.sh <slug>` 丢进 P00-misc
- 提醒一句最重要的规矩:**AI 不会自动帮他建任务/归档,他得开口说**

别写长篇。他刚克隆完一个库,想的是赶紧开始干活,不是读你的报告。

---

## 手动安装(人类看这里)

```bash
git clone https://github.com/andyleimc-source/workmd.git
cd workmd
rm -rf .git && git init                        # 断开与上游的联系，这是你自己的库了
chmod +x scripts/*.sh scripts/hooks/*.sh
git add -A && git commit -m "init"
```

依赖:`bash` / `git` / `python3` / `perl`(macOS 和多数 Linux 自带)。外挂一个都不装也能用。

第一个项目:
```bash
./scripts/new-project.sh my-first-project
./scripts/new-task.sh first-task P01
```

零散小事(不建项目):
```bash
./scripts/new-task.sh buy-monitor            # 自动落到 P00-misc
```
