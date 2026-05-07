# AI_Notes 标准化规范

*从 README.md 提取的核心守则，专注数据同步和AI协同规范。*

---

## 群聊协作规则（铁律）

### @ 规则
- 没被 @ 就不回复（小耗子直接 @ 的情况除外）
- 已经回复了，不重复回复
- **@ 其他 agent 必须放消息最后，不能放开头**
- 分多条消息时，只在最后一条 @ 对方
- 原因：先说内容，最后 @，对方看到后才回复，避免抢答

### 抢答问题
- 对方已经回了，不重复回复
- 分多条消息发送时，等对方发完再回复

---

## 定时同步机制

### 原则：各管各的

每个 agent 只同步自己的内容到自己的目录，不混在一起。

### 同步脚本（Windows 示例）

```powershell
# sync.ps1
$repo = "AI_Notes"
$memory = "memory"
$memoryTarget = "$repo/OpenClaw_Configuration/[名字]-[平台]/memory"
$configTarget = "$repo/OpenClaw_Configuration/[名字]-[平台]"

# Step 1: Git 拉取
cd $repo
git pull origin main

# Step 2: 同步 memory 到自己的目录
Copy-Item -Recurse -Force "$memory/*" "$memoryTarget/"

# Step 3: 同步工作区配置（脱敏）
Copy-Item -Force "~/.openclaw/openclaw.json" "$configTarget/openclaw.json"
# 工作区文件
Copy-Item -Force "AGENTS.md" "$configTarget/"
Copy-Item -Force "SOUL.md" "$configTarget/"
Copy-Item -Force "MEMORY.md" "$configTarget/"
# ... 其他工作区文件

# Step 4: 敏感信息清理
Get-ChildItem "$memoryTarget" -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace 'sk-[a-zA-Z0-9]{20,}', '***REDACTED***'
    $content = $content -replace '"private_key":\s*"-----BEGIN PRIVATE KEY-----\\n[^"]*"', '"private_key": "***REDACTED***"'
    $content = $content -replace '"private_key_id":\s*"[^"]*"', '"private_key_id": "***REDACTED***"'
    $content = $content -replace '"client_email":\s*"[^"]*"', '"client_email": "***REDACTED***"'
    $content = $content -replace '"client_id":\s*"[^"]*"', '"client_id": "***REDACTED***"'
    Set-Content $_.FullName $content
}

# 配置文件脱敏
$cfg = Get-Content "$configTarget/openclaw.json" -Raw
$cfg = $cfg -replace '"apiKey":\s*"[^"]*"', '"apiKey": "***REDACTED***"'
$cfg = $cfg -replace '"token":\s*"[^"]*"', '"token": "***REDACTED***"'
$cfg = $cfg -replace '\d{10}:[A-Za-z0-9_-]{35}', '***REDACTED***'
Set-Content "$configTarget/openclaw.json" $cfg

# Step 5: Git 推送
cd $repo
git add .
git commit -m "定时同步 $(Get-Date -Format 'yyyy-MM-dd_HH:mm')"
git push origin main
```

### 定时任务

**Windows（计划任务）**：
```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File sync.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6)
Register-ScheduledTask -TaskName "AI_Notes_Sync" -Action $action -Trigger $trigger
```

**Linux（crontab）**：
```bash
(crontab -l 2>/dev/null; echo "0 */6 * * * ~/sync.sh") | crontab -
```

---

## 敏感信息清理

**重要**：同步脚本会自动清理以下敏感信息：

- API keys（`sk-xxx`、`apiKey: xxx`、OpenRouter、Apify 等）
- Telegram Bot Token（`\d{10}:[A-Za-z0-9_-]{35}`）
- Google Cloud credentials（`private_key`、`client_email`、`client_id`）
- 其他 token 和密钥

**防护机制**：
1. 同步脚本自动脱敏
2. Git 推送保护（GitHub Secret Scanning）
3. GitGuardian 监控

**安全建议**：
- 不要直接发完整的 API key 给 agent
- 重要密钥不要存在 memory 文件里
- 配置备份必须脱敏后再提交

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

### 原则
- **各管各的**：每个 agent 只同步到自己的目录
- **不混在一起**：没有共享 memory 目录
- **自动脱敏**：配置和 memory 都要清理敏感信息

### 目录结构
```
OpenClaw_Configuration/
├── stephen-win/
│   ├── openclaw.json      # 配置备份（脱敏）
│   ├── AGENTS.md           # 工作区文件备份
│   ├── SOUL.md
│   ├── MEMORY.md
│   └── memory/             # memory 备份
└── zin-linux/
    ├── openclaw.json
    └── memory/
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
- 推送未脱敏的配置到 GitHub

---

*最后更新：2026-05-08*
*来源：README.md 提取*
*维护者：小耗子*