# AI_Notes 使用规则

## 这是什么？

`AI_Notes` 是所有 OpenClaw agent 共享的 **Obsidian 知识库**，用于统一管理记忆、wiki、日记和研究成果。

---

## 目录结构

```
AI_Notes/
├── 00_收件箱/              # 临时收集，待整理
├── 10_日记/                # 每日记录（YYYY-MM-DD.md）
├── 20_项目/                # 项目文档
├── 30_研究/                # 研究笔记
├── 40_知识库/              # 长期知识沉淀
├── 50_资源/                # 参考资料、模板
├── 90_计划/                # 规划和待办
├── 99_系统/                # 系统配置、模板、提示词、归档
├── OpenClaw_WiKi/          # 各 agent 的 Memory-Wiki
│   ├── stephen-win/        # stephen 的 wiki 目录
│   └── zin-linux/          # zin 的 wiki 目录
├── OpenClaw_Configuration/ # 各 agent 配置备份（各管各的）
│   ├── stephen-win/        # stephen 配置 + memory
│   └── zin-linux/          # zin 配置 + memory
└── .agents/skills/         # 技能脚本
```

---

## 可用命令

| 命令 | 作用 |
|------|------|
| `/开始我的一天` | 每日规划，回顾昨天、规划今天 |
| `/启动项目` | 把想法变成项目 |
| `/研究` | 深度研究某个主题 |
| `/AI通讯` | 抓取 AI 通讯摘要 |
| `/AI产品` | 抓取 AI 产品发布 |
| `/归档` | 归档已完成项目和收件箱 |
| `/提问` | 快速问答，不记笔记 |
| `/整理知识` | 把非结构化文本转成知识库 |
| `/头脑风暴` | 创意发散 |
| `/同步` | Git 同步、memory 备份、工作区配置备份、推送云端 |

---

## 已注册 Agent

| 名称 | 平台 | 路径 | 用途 | 权限 |
|------|------|------|------|------|
| zin | Linux | `OpenClaw_WiKi/zin-linux` | VPS 主 agent | 主控 |
| stephen | Windows | `OpenClaw_WiKi/stephen-win` | 本地 Windows agent | 独立 |

---

## 新 Agent 注册

### 1. 创建目录
```bash
mkdir -p AI_Notes/OpenClaw_WiKi/[名字]-[平台]
mkdir -p AI_Notes/OpenClaw_Configuration/[名字]-[平台]/memory
```

### 2. 复制工作区文件
将 `AGENTS.md`、`SOUL.md`、`MEMORY.md` 等复制到配置目录。

### 3. 修改配置
编辑 `~/.openclaw/openclaw.json`，启用 memory-wiki 插件，指向你的 wiki 目录。

### 4. 重载并设置同步
```bash
openclaw gateway restart
```
参考 `Standardization.md` 中的同步原则，创建自己的同步脚本。

### 5. 配置 SSH 认证
将 SSH 公钥添加到 GitHub，否则无法推送。

---

## 同步原则

### 核心：各管各的
- 每个 agent 只同步自己的内容到自己的目录
- 没有共享 memory 目录
- 自动脱敏后才能推送

### 脱敏要求
- API keys、Telegram tokens、Google Cloud credentials 等必须清理
- 配置备份必须脱敏后再提交
- 使用同步脚本自动清理

---

## 10_日记 整理权限

### 主控 Agent（zin-linux）
- ✅ 可自动归纳整理各 agent 的日记
- ✅ 可创建、修改 `10_日记/` 下的文件

### 其他 Agent
- ❌ 默认不可整理 `10_日记/`
- ✅ 需要用户明确授权后才可整理

---

## 规范

### ✅ 允许
- 在自己的目录下自由创建内容
- 读取其他 agent 的配置
- 主控自动整理日记

### ❌ 禁止
- 修改其他 agent 的目录
- 推送未脱敏的配置到 GitHub
- 未经授权整理 `10_日记/`

---

## 常见问题

**Q: 共享内容？** → 放到 `40_知识库`，注明来源

**Q: 看其他 agent 配置？** → 读 `OpenClaw_Configuration/[名字]-[平台]/`

**Q: 我的日记什么时候被整合？** → 主控每日自动整合

**Q: Git 推送失败？** → 检查 SSH 认证：`ssh -T git@github.com`

**Q: GitGuardian 报警？** → 重写 git 历史 + 更新脱敏规则 + force push

---

*最后更新：2026-05-08*
*维护者：小耗子*