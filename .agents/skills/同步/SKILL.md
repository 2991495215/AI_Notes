---
name: 同步
description: Git 同步、memory 备份、整合其他 agent 日记、生成今日日记
---

当用户发送 `/同步` 时，按以下流程执行：

# 流程

## Step 1: Git 拉取云端内容

```bash
cd /root/openclaw-workspace/AI_Notes
git pull origin main
```

如果有冲突，提示用户解决。

## Step 2: 同步 memory 文件夹

```bash
rsync -av --update /root/openclaw-workspace/memory/ /root/openclaw-workspace/AI_Notes/OpenClaw_Configuration/memory/
```

同步完成后，统计新增/修改的文件数量。

## Step 3: 整合其他 agent 的日记

1. **查看已有 agent 目录**：
   ```bash
   ls /root/openclaw-workspace/AI_Notes/OpenClaw_WiKi/
   ```

2. **读取每个 agent 目录下的今日日记**：
   - 路径格式：`OpenClaw_WiKi/[agent名]/10_日记/YYYY-MM-DD.md`
   - 如果存在今天的日记，读取内容

3. **整合到主日记**：
   - 读取 `/root/openclaw-workspace/AI_Notes/10_日记/YYYY-MM-DD.md`（如果存在）
   - 将其他 agent 的日记内容整合进去
   - 保留原有内容，追加新内容
   - 如果主日记不存在，创建新的

4. **整合格式**：
   ```markdown
   # YYYY-MM-DD 每日记录

   ## zin-linux 的记录
   [zin-linux 的日记内容]

   ## [其他agent] 的记录
   [其他agent 的日记内容]

   ## 整合摘要
   - [关键事项1]
   - [关键事项2]
   ```

## Step 4: Git 推送

```bash
cd /root/openclaw-workspace/AI_Notes
git add .
git commit -m "同步更新 YYYY-MM-DD"
git push origin main
```

# 输出格式

完成后，向用户汇报：

```
## 同步完成

**Git 状态：**
- 拉取：[成功/有冲突]
- 推送：[成功/失败]

**Memory 同步：**
- 同步文件数：[N]
- 新增：[N]
- 修改：[N]

**日记整合：**
- 已整合 agent：[列表]
- 主日记：10_日记/YYYY-MM-DD.md

**下一步：**
- [ ] 检查日记内容
- [ ] 处理冲突（如有）
```

# 注意事项

- 如果其他 agent 没有今日日记，跳过
- 如果主日记已存在，追加而不是覆盖
- 保留原有内容，只追加新内容
- Git 冲突时暂停，提示用户手动解决
