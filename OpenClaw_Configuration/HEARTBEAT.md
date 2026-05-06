# HEARTBEAT.md — 定时任务

## 触发条件
本任务由系统心跳调用（内部调度）。不再依赖任何特定关键词触发。

## 每次心跳必执行（静默）

1.  **工作区清理：** 扫描工作区 (`/root/openclaw-workspace`)，发现非记忆类文件（如 `.png`, `.jpg`, `.exe`, `.zip`, `.ps1` 等）立即转移至 `/root/openclaw-workspace/` 下对应的分类目录（如 `Media`, `Scripts`, `Downloads`）。保持工作区根目录仅含核心 MD 文件与 memory 文件夹。
2. **运行状态检查**
   - 检查是否存在明显失败中的关键 cron / 备份 / 服务异常