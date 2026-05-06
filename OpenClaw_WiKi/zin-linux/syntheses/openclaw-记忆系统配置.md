---
pageType: synthesis
id: synthesis.openclaw-记忆系统配置
title: OpenClaw 记忆系统配置
sourceIds:
  - memory/2026-05-07.md
confidence: 0.9
status: verified
updatedAt: 2026-05-06T21:26:18.031Z
---

# OpenClaw 记忆系统配置

## Notes
<!-- openclaw:human:start -->
<!-- openclaw:human:end -->

## Summary
<!-- openclaw:wiki:generated:start -->
# OpenClaw 记忆系统配置

## 当前启用的记忆插件

### 1. memory-core
- **状态**：已启用
- **功能**：核心记忆系统，提供 `memory_get` 和 `memory_search` 工具
- **配置**：
  - 向量搜索：基于 MEMORY.md 和 memory/*.md
  - 嵌入模型：baai/bge-m3（通过 OpenRouter）
  - Dreaming 功能：**已禁用**（避免内容堆积）

### 2. memory-wiki
- **状态**：已启用
- **功能**：Wiki 风格记忆系统
- **配置**：
  - Vault 模式：isolated
  - 渲染模式：obsidian
  - 路径：`/root/openclaw-workspace/AI_Notes/OpenClaw_WiKi/zin-linux`

### 3. active-memory
- **状态**：未启用
- **功能**：实时记忆召回系统，在每次回复前自动注入相关记忆

## 记忆分层规则

根据 AGENTS.md 规则：
- **每日记录**：`memory/YYYY-MM-DD.md`（当天事实、决策、异常）
- **长期记忆**：`MEMORY.md`（长期有效、高复用、跨会话重要）

## 已禁用的功能

### Memory Dreaming Promotion
- **原因**：自动将短期记忆提升到 MEMORY.md，导致内容堆积
- **问题**：格式混乱、无自动清理机制
- **解决**：已禁用，改为人工审核后手动添加

## 参考文档
- 配置文件：`/root/.openclaw/openclaw.json`
- 每日记录：`/root/openclaw-workspace/memory/`
- 长期记忆：`/root/openclaw-workspace/MEMORY.md`
<!-- openclaw:wiki:generated:end -->

## Related
<!-- openclaw:wiki:related:start -->
- No related pages yet.
<!-- openclaw:wiki:related:end -->
