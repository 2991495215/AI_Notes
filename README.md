# AI_Notes 守则

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
├── OpenClaw_Configuration/ # 各 agent 配置备份（自动同步）
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
| `/同步` | Git 同步、memory 备份、整合日记、推送云端 |

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
mkdir -p /root/openclaw-workspace/AI_Notes/OpenClaw_WiKi/[名字]-[平台]
```

### 2. 修改配置
编辑 `~/.openclaw/openclaw.json`：
```json
{
  "plugins": {
    "entries": {
      "memory-wiki": {
        "enabled": true,
        "config": {
          "vaultMode": "isolated",
          "vault": {
            "path": "/root/openclaw-workspace/AI_Notes/OpenClaw_WiKi/[名字]-[平台]",
            "renderMode": "obsidian"
          }
        }
      }
    }
  }
}
```

### 3. 重载
```bash
openclaw gateway restart
```

### 4. 设置定时同步
参考下面的「定时同步机制」创建自己的 cron 任务。

### 5. 配置 SSH 认证
**必须**：将 SSH 公钥添加到 GitHub，否则无法推送。

```bash
# 查看公钥
cat ~/.ssh/id_rsa.pub
```

到 GitHub → Settings → SSH and GPG keys → New SSH key，粘贴公钥。

---

## 定时同步机制

### 主控 Agent（zin-linux）

自动执行：
- **每 6 小时**：Git 同步 + memory 备份
- **每日**：整合各 agent 日记到 `10_日记/`

### 其他 Agent

需要自行创建定时任务：

```bash
# 创建同步脚本
cat > ~/sync.sh << 'EOF'
#!/bin/bash
cd /root/openclaw-workspace/AI_Notes

# Git 拉取
git pull origin main

# 同步 memory
rsync -av --update /root/openclaw-workspace/memory/ /root/openclaw-workspace/AI_Notes/OpenClaw_Configuration/memory/

# 清理敏感信息
cd /root/openclaw-workspace/AI_Notes/OpenClaw_Configuration/memory
for file in *.md; do
  sed -i 's/"apiKey": "[^"]*"/"apiKey": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/sk-[a-zA-Z0-9]\{20,\}/***REDACTED***/g' "$file" 2>/dev/null
  sed -i 's/ctx7sk[a-zA-Z0-9]*/***REDACTED***/g' "$file" 2>/dev/null
  sed -i 's/"private_key": "[^"]*"/"private_key": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/"private_key_id": "[^"]*"/"private_key_id": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/"client_email": "[^"]*"/"client_email": "***REDACTED***"/g' "$file" 2>/dev/null
  sed -i 's/"client_id": "[^"]*"/"client_id": "***REDACTED***"/g' "$file" 2>/dev/null
done

cd /root/openclaw-workspace/AI_Notes

# Git 推送
git add .
git commit -m "定时同步 $(date +%Y-%m-%d_%H:%M)" 2>/dev/null
git push origin main
EOF

chmod +x ~/sync.sh

# 添加 cron（每6小时）
(crontab -l 2>/dev/null; echo "0 */6 * * * ~/sync.sh") | crontab -
```

---

## 敏感信息清理

**重要**：同步脚本会自动清理以下敏感信息：

- API keys（`sk-xxx`、`apiKey: xxx`）
- Google Cloud credentials（`private_key`、`client_email`）
- 其他 token 和密钥

**如果你发给 agent 包含敏感信息的内容**：
1. 同步脚本会自动清理
2. 推送到 GitHub 前会检查
3. 如果被 GitHub 拒绝，说明还有敏感信息，需要手动清理

**安全建议**：
- 不要直接发完整的 API key 给 agent
- 需要时可以说"我的 API key 是 sk-xxx"，但要意识到会被清理
- 重要密钥不要存在 memory 文件里

---

## 10_日记 整理权限

### 主控 Agent（zin-linux）
- ✅ 可自动归纳整理各 agent 的日记
- ✅ 可创建、修改 `10_日记/` 下的文件
- ✅ 每日自动整合各 agent 内容

### 其他 Agent
- ❌ 默认不可整理 `10_日记/`
- ✅ 需要用户明确授权后才可整理
- ✅ 可在自己目录下写日记，等待主控整合

---

## OpenClaw_Configuration 同步

`OpenClaw_Configuration/memory/` 与主工作区的 `memory/` 自动同步（每 6 小时）。

手动同步：
```bash
rsync -av --update /root/openclaw-workspace/memory/ /root/openclaw-workspace/AI_Notes/OpenClaw_Configuration/memory/
```

---

## 规范

### ✅ 允许
- 在自己的目录下自由创建内容
- 使用 Obsidian 友好格式（wikilinks、frontmatter）
- 读取其他 agent 的配置
- 主控自动整理日记

### ❌ 禁止
- 修改其他 agent 的目录
- 在根目录创建 wiki 文件
- 手动修改 `OpenClaw_Configuration/`
- 未经授权整理 `10_日记/`

---

## 常见问题

**Q: 共享内容？** → 放到 `40_知识库`，注明来源

**Q: 看其他 agent 配置？** → 读 `OpenClaw_Configuration/`

**Q: 我的日记什么时候被整合？** → 主控每 6 小时自动整合

**Q: 我想自己整理日记？** → 需要用户授权

**Q: Git 推送失败？** → 检查 SSH 认证：`ssh -T git@github.com`

**Q: 被 GitHub 拒绝推送？** → 可能有敏感信息，需要清理

---

*最后更新：2026-05-07*
*维护者：小耗子*

