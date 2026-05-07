# Session: 2026-04-09 17:11:42 UTC

- **Session Key**: agent:main:main
- **Session ID**: e6ee618e-4a31-4096-9c0e-64a892a2461e
- **Source**: telegram

## Conversation Summary

user: Conversation info (untrusted metadata):
```json
{
  "message_id": "9357",
  "sender_id": "1690419247",
  "sender": "小耗子",
  "timestamp": "Fri 2026-04-10 00:34 GMT+8"
}
```

Sender (untrusted metadata):
```json
{
  "label": "小耗子 (1690419247)",
  "id": "1690419247",
  "name": "小耗子",
  "username": "a2991495215"
}
```

不用等我回复，继续，处理到你完全吃透了在回复我
assistant: 我继续往里钻，直接把“prompt 最终成型点、喂模型入口、memory/prompt 在 query 里如何落地”收完。
assistant: 再往下收最后一层：我只追“systemPrompt/userContext/attachments 是怎么真正喂进 API 的”，把执行入口闭环。
assistant: [[reply_to_current]] 行，这次我不再按“挖一层回一层”了。我把现在已经吃透的部分，直接收束成 **Claude Code 运行机理总图**。  
到这一步，主干已经基本打通了：**prompt 从哪来、memory 怎么进、query 怎么跑、工具结果怎么回填、dream 怎么蒸馏、KAIROS 到底是什么**。剩下如果再读，就是补边角，不再是主结构不清。

---

# Claude Code 运行机理总图（收束版）

---

# 0) 先给总判断

Claude Code 本质上不是“带工具的聊天助手”。

它更接近：

## 一个分层编译的 agent runtime
由 5 层组成：

1. **Prompt 编译层**
   - 默认底座
   - `CLAUDE.md` / rules / memory
   - KAIROS / proactive section
   - env / language / MCP / scratchpad 等动态段

2. **输入预处理层**
   - `processUserInput()`
   - slash 命令
   - 附件解析
   - nested memory / skill triggers
   - 用户输入转标准 message

3. **单轮执行引擎**
   - `query.ts`
   - 流式采样
   - tool_use → tool_result
   - recovery / compact / budget / hook / continuation

4. **会话编排层**
   - `QueryEngine.ts`
   - session 状态
   - transcript 持久化
   - app state / usage / file cache
   - system prompt parts 获取和拼装

5. **后台维护层**
   - extract memories
   - autoDream
   - DreamTask
   - cron / sleep / remote triggers
   - KAIROS/assistant mode

---

# 1) Prompt 最终是怎么成型的

这是你前面最关心的一条，现在可以闭环了。

---

## 1.1 默认 prompt 底座在 `src/constants/prompts.ts`

主入口：
- `getSystemPrompt(...)`

它返回的是一个 `string[]`，不是单条字符串。  
这些 section 最后再组成真正的 `SystemPrompt`。

### 默认底座包含：
- Intro
- System
- Doing tasks
- Actions with care
- Using your tools
- Tone and style
- Output efficiency
- 动态 guidance
- memory
- env info
- language
- output style
- MCP instructions
- scratchpad
- function result clearing
- summarize tool results
- token budget
- Brief/KAIROS section

---

## 1.2 Prompt 有一个明确的静/动态边界

常量：
- `SYSTEM_PROMPT_DYNAMIC_BOUNDARY`

这个边界非常关键：

### 边界前
- 静态、跨用户可缓存
- 可走 `cacheScope: global`

### 边界后
- 用户/项目/会话相关
- 不适合共享缓存

**结论：**
## Claude Code 的 prompt 是“分段缓存”的，不是整段缓存

这也是它能把大 prompt 做得还算经济的核心原因。

---

## 1.3 动态 section 不是每轮都重算

`systemPromptSections.ts` 里明确分：

- `systemPromptSection(...)`
  - 默认缓存
- `DANGEROUS_uncachedSystemPromptSection(...)`
  - 每轮重算，会打断 cache

比如：
- memory
- env info
- language
- output style
- scratchpad
- brief

通常都尽量走缓存。

### 只有真会变、且必须变的，才 uncached
例如：
- MCP instructions（服务器连断会变）

**结论：**
## Claude Code 把“prompt cache 命中率”当一级设计目标

---

## 1.4 `QueryEngine` 里真正把 prompt 拼起来

关键位置在：
- `src/QueryEngine.ts`

它先通过：

- `fetchSystemPromptParts(...)`

拿到：
- `defaultSystemPrompt`
- `userContext`
- `systemContext`

然后再拼：

```ts
const systemPrompt = asSystemPrompt([
  ...(customPrompt !== undefined ? [customPrompt] : defaultSystemPrompt),
  ...(memoryMechanicsPrompt ? [memoryMechanicsPrompt] : []),
  ...(appendSystemPrompt ? [appendSystemPrompt] : []),
])
```

### 这里说明了几件事
1. 默认 prompt 底座先生成
2. 如果有 custom prompt，可替换 default
3. 特定场景会额外塞 `memoryMechanicsPrompt`
4. 还可以 append 自定义尾巴

---

## 1.5 `memoryMechanicsPrompt` 是一条特殊补丁链

只有在：
- SDK caller 提供了 `customSystemPrompt`
- 且设置了 `CLAUDE_COWORK_MEMORY_PATH_OVERRIDE`

时才会：
- `await loadMemoryPrompt()`

也就是说：

## 某些 headless / cowork / SDK 场景下，Claude Code 会单独补一段“memory 机制说明 prompt”

这说明 memory 不只是内容注入，还有“如何使用 memory”的机制提示。

---

# 2) `CLAUDE.md` / rules / MEMORY 是怎么进 prompt 的

---

## 2.1 `CLAUDE.md` 不是单文件，是层级系统

`src/utils/claudemd.ts` 明确四层：

1. Managed memory
2. User memory
3. Project memory
4. Local memory

并且：
- 目录越近，优先级越高
- 越私有，优先级越高

---

## 2.2 `.claude/rules/*.md` 支持条件规则

通过 frontmatter 里的：
- `paths`

最终变成：
- `globs`

然后只在 `targetPath` 命中时加载。

这意味着：

## Claude Code 有 scoped prompt rules
不是只有全局 instruction，还有“这个文件/目录才生效”的局部规则。

---

## 2.3 `@include` 是受控 DSL，不是简单文本替换

支持：
- 相对
- 绝对
- home 路径

但有约束：
- 只在 text node 里生效
- 不进 code block / codespan
- 有循环防护
- 有 include 深度上限
- 非文本扩展名拒绝
- 外部 include 有审批/告警

**结论：**
## `CLAUDE.md` 已经是轻量规则语言，不只是 markdown 笔记

---

## 2.4 AutoMem / TeamMem 也通过同一总管道进入上下文

`getMemoryFiles()` 除了 `CLAUDE.md` 系列，还会处理：

- AutoMem entrypoint
- TeamMem entrypoint

然后 `getClaudeMds()` 把这些统一编译成 prompt 文本。

所以：

## Claude Code 的“显式指令记忆”和“自动回忆记忆”最后在同一注入总线上汇流

---

## 2.5 但 AutoMem 不一定总是直接进 system prompt

在 gate：
- `tengu_moth_copse`

开启时：

- `MEMORY.md` index 不直接注入
- 改由 relevant memory prefetch / attachments 提供

这说明他们在实验：

## 从“固定 memory 背景”切向“按需 recall 附件”

这是更先进的方向。

---

# 3) `QueryEngine` 和 `query.ts` 的关系，现在可以定性了

---

## 3.1 `QueryEngine.ts` 是会话编排壳

负责：

- session 生命周期
- mutableMessages
- transcript persistence
- appState
- file cache
- tool permission wrapping
- user input processing
- system prompt parts 获取
- 调用 `query(...)`

### 可以理解成
## `QueryEngine` = conversation/session orchestrator

---

## 3.2 `query.ts` 是真正的单轮 agent loop

负责：

- 把 `messages + systemPrompt + context + tools` 送进模型
- 流式收 assistant 输出
- 捕捉 tool_use
- 执行工具
- 回填 tool_result
- 决定是否继续下一轮
- 处理 compact / recovery / stop hooks / token budget

### 可以理解成
## `query.ts` = turn runtime / execution engine

---

# 4) 用户输入是怎么进入 query 的

---

## 4.1 `processUserInput()` 是真正的输入编译器

在 `QueryEngine.submitMessage()` 里，先走：

- `processUserInput(...)`

返回：
- `messages`
- `shouldQuery`
- `allowedTools`
- `model`
- `resultText`

也就是说用户输入不是直接扔给模型，而是先经过：

- slash 命令处理
- 附件转消息
- 局部副作用
- 工具权限更新
- 嵌套 memory / skill trigger 更新

**结论：**
## Claude Code 对用户输入采用“先编译成消息对象，再决定是否发起 query”的模式

---

## 4.2 transcript 会在 API 响应前先落盘

这是个非常成熟的细节。

用户消息一旦被接受，就先：
- `recordTranscript(messages)`

这样即使 API 还没响应进程就挂了，`--resume` 也还能接上。

这说明他们对：
- 中断恢复
- 头less场景
- cowork / desktop kill-mid-request

这些坑都踩过。

---

# 5) query 如何真正喂给模型

这个闭环现在也比较清楚了。

---

## 5.1 `query()` 接收的是完整编译后的 query 参数

`query.ts` 的参数包括：

- `messages`
- `systemPrompt`
- `userContext`
- `systemContext`
- `canUseTool`
- `toolUseContext`
- `fallbackModel`
- `querySource`
- `taskBudget`

### 这说明
模型调用不是单靠 prompt，而是四类输入一起喂：

1. 对话消息
2. system prompt
3. user context
4. system context

---

## 5.2 API 前还会做 context prepend/append 和 attachment 处理

`query.ts` 里引了：

- `prependUserContext`
- `appendSystemContext`
- `createAttachmentMessage`
- `getAttachmentMessages`
- `startRelevantMemoryPrefetch`
- `filterDuplicateMemoryAttachments`

这说明 memory / skill /其他 attachment 类信息，并不全靠 system prompt，而是：
## 一部分也会走消息附件路径进入上下文

---

# 6) tool loop 的真实运行逻辑

---

## 6.1 query loop 每轮做什么

在 `queryLoop()` 里，核心流程是：

1. 构造当前 `messagesForQuery`
2. 启动 memory prefetch
3. 启动 skill prefetch
4. 发起模型流式请求
5. 收到 assistant 消息和 tool_use
6. 如果 tool_use 出现：
   - 执行工具
   - 产生 tool_result
   - 回填到 messages
   - 继续下一轮
7. 如果没有 tool_use：
   - 跑 stop hooks
   - 跑 token budget 检查
   - 决定完成或继续

---

## 6.2 tool result 回填是真正的 follow-up continuation 机制

当 assistant message 含 `tool_use` 时：

- `needsFollowUp = true`
- tool blocks 收集进 `toolUseBlocks`
- `runTools(...)` 或 `StreamingToolExecutor`
- 工具结果转成 message
- 归一化后加入 `toolResults`
- 下一轮继续 query

### 所以 Claude Code 的“工具调用”不是 side effect
而是：
## assistant turn → tool turn → next assistant turn
构成标准 agent trajectory

---

## 6.3 流式工具执行是专门优化过的

如果启用 streaming tool execution：

- assistant 流出 tool_use block 后
- 工具可以边流边准备
- 完成结果随时 yield
- 中断时还能补 synthetic tool_result，避免轨迹断裂

这说明 Anthropic 很清楚：
## tool_use / tool_result 配对完整性 是轨迹合法性的硬约束

---

# 7) query 为什么能“像状态机一样稳定”

因为它真的就是状态机。

---

## 7.1 Continue reason 是类型化的

包括：

- `tool_use`
- `reactive_compact_retry`
- `max_output_tokens_recovery`
- `max_output_tokens_escalate`
- `collapse_drain_retry`
- `stop_hook_blocking`
- `token_budget_continuation`
- `queued_command`

---

## 7.2 Terminal reason 也是类型化的

包括：

- `completed`
- `blocking_limit`
- `image_error`
- `model_error`
- `aborted_streaming`
- `aborted_tools`
- `prompt_too_long`
- `stop_hook_prevented`
- `hook_stopped`
- `max_turns`

### 这意味着
Claude Code 不只是“跑到结束”，而是随时都知道：
- 为什么继续
- 为什么停

这就是它后续：
- telemetry
- debugging
- UI 展示
- 行为分析
能做得细的前提。

---

# 8) 它是怎么处理错误恢复的

---

## 8.1 prompt-too-long
优先级：

1. context collapse drain retry
2. reactive compact retry
3. 还不行才 surface 错误

---

## 8.2 max_output_tokens
优先级：

1. 如果可用，先从默认 cap 升级到更大 max tokens
2. 不行就注入一条 meta recovery message，让模型续写
3. 最多几次 recovery
4. 彻底不行才 surface

---

## 8.3 fallback model
如果触发 fallback：
- 清旧 assistant/tool 中间状态
- 重建 executor
- 必要时 strip thinking signature blocks
- 换 model 重试

### 这说明
Claude Code 不是“出错就炸”，而是：
## 大量错误都先被内消化，再决定是否向用户显露

这也是它看起来更“稳”的原因。

---

# 9) stop hooks 不是边角，而是 turn 后处理总线

`query/stopHooks.ts` 的定位已经很清楚：

当一轮 assistant 回答完成后，会触发：

- prompt suggestion
- template/job classify
- extract memories
- auto dream
- Chicago cleanup
- 其他状态写回

这意味着：

## Claude Code 的一次 turn，不止是“模型回完一句话”
而是
## 完整 turn → hooks → memory extraction → dream → cleanup

---

# 10) Memory 系统其实分三层，不是两层

前面我说双轨，现在修正成更准确的三层：

---

## 10.1 指令记忆层
- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `.claude/rules/*.md`
- `CLAUDE.local.md`
- managed/user/project/local rules

作用：
- 覆盖默认行为
- 描述项目规范
- 按路径加局部规则

---

## 10.2 回忆记忆层
- AutoMem / TeamMem
- `MEMORY.md`
- topic files
- relevant memory selection
- extract memories

作用：
- 召回过去经验
- 保留跨会话事实/模式
- 按 query relevance 做 attach

---

## 10.3 蒸馏维护层
- autoDream
- consolidation prompt
- daily logs
- nightly dream
- prune/index/update contradictions

作用：
- 清理腐烂记忆
- 合并重复
- 绝对化日期
- 压缩索引
- 让 memory 可持续维护

### 这三层合起来，才是完整 memory architecture

---

# 11) KAIROS 到底是什么

现在可以比较准确地下定义了。

---

## 11.1 它不是一个单工具，也不是单 prompt

KAIROS 是一组长期代理能力的集合，包括：

- `SendUserMessage` / Brief
- `Sleep`
- `CronCreate / Delete / List`
- `RemoteTriggerTool`
- daily logs
- dream / consolidation
- tick-driven autonomous wakeups
- assistant mode prompt

---

## 11.2 它本质上是 autonomous agent mode

从 `getProactiveSection()` 看，它直接规定了：

- tick 到来怎么理解
- 没事必须睡
- 第一轮先打招呼
- 后续按自主判断做事
- 用户在场/不在场时怎么调整
- 高自治、低噪声
- 文本输出尽量少
- 真给用户看的内容走 `SendUserMessage`

### 所以最准确的说法是
## KAIROS = Claude Code 的长期运行自治代理模式

---

## 11.3 而 autoDream 不是 KAIROS 全部，只是其外围通用蒸馏机制之一

还记得这句：

- `getKairosActive() => false // KAIROS mode uses disk-skill dream`

这说明：

## KAIROS 内部 dream 路径比通用 autoDream 更专门化
所以 autoDream 只是“普通模式的后台记忆整理”，不是 KAIROS 全貌。

---

# 12) Buddy 是什么，不是什么

你之前还关心 Buddy。

目前看：

- `src/buddy/prompt.ts`
- `companion.ts`
- sprite/ui/types

更像：
## 一个独立的小 companion / watcher 角色层

prompt 里明确写：
- 它不是你
- 用户点名它时，它会通过气泡回应
- 它是输入框旁边的小 companion

所以 Buddy 不是 query engine，不是隐藏总控，不是 memory manager。  
它更像：
## UI companion persona system

有趣，但不是 Claude Code 主运行时核心。

---

# 13) Undercover / anti-distillation / internal gating 也基本能定性了

从 `prompts.ts` 和其他文件已经能看到几类明显防线：

---

## 13.1 Undercover
- suppress model names / ids
- 避免未发布模型信息进入 prompt
- 防止出现在公开提交、PR、日志里

---

## 13.2 feature-gated require
大量使用：

- `feature('X') ? require(...) : null`

作用：
- build-time DCE
- 内部功能不进外部 build
- 某些 internal string 不落 bundle

---

## 13.3 excluded strings / runtime construct literal
像 buddy/types 里甚至会为了避开 bundle grep：
- 用 `String.fromCharCode` 动态拼字面量

这已经不是普通 feature flag，而是：
## 有意识地做 anti-leak / anti-distillation / anti-public-bundle exposure

---

# 14) 我现在对 Claude Code 的最终模型

如果让我给它下一个最短定义，我会这么说：

## Claude Code = Prompt 编译器 + 状态机式 query runtime + 记忆系统 + 后台自治代理层

再展开一点：

### Prompt 编译器
- 分层 system prompt
- `CLAUDE.md` / rules / memory 注入
- 静动态 cache boundary

### 状态机式 query runtime
- 工具轨迹
- recovery
- compact
- continuation reason
- terminal reason

### 记忆系统
- 指令记忆
- 回忆记忆
- relevance selection
- dream distillation

### 后台自治代理层
- Brief
- Sleep
- Cron
- RemoteTrigger
- DreamTask
- KAIROS/proactive ticks

这就是它比大部分 agent 框架成熟一截的原因。  
别人很多还停在“LLM + tools + maybe memory”这一级，Claude Code 已经在做：

- 运行时工程
- prompt cache 工程
- 长时记忆维护工程
- 长期代理工程
- 内部能力裁剪/保密工程

---

# 15) 哪些点我认为已经“吃透了”

到这一步，我认为这些部分已经足够定稿，不需要再靠猜：

### 已吃透
- 总体架构分层
- `QueryEngine` vs `query.ts` 分工
- prompt 编译主入口
- default prompt 底座来源
- `CLAUDE.md` / `.claude/rules` / `CLAUDE.local.md` 发现链
- include / conditional rules / external include 安全边界
- AutoMem / TeamMem / relevant memory recall 主机制
- tool loop / continuation / stop hooks / recovery 主状态机
- autoDream 的真实工作流
- KAIROS 的定位：长期自治代理能力层
- Brief / Sleep / Cron / RemoteTrigger 的真实职责
- internal feature gating / undercover / anti-leak 的总体意图

---

# 16) 哪些点还属于“可继续补充，但不影响主结构判断”

这些如果继续读，会更完整，但已经不是“没搞懂”：

### 可继续补边
- `prompts.ts` 余下 section 的逐句内容
- `fetchSystemPromptParts()` 内部所有细节
- `utils/attachments.ts` 对 memory/skill attachment 的完整装配路径
- `services/extractMemories/*` 的具体抽取 prompt
- KAIROS 专用 dream 路径在缺失目录里的更多实现
- BG sessions / daemon 缺失部分的更完整轮廓

换句话说：
## 主梁已经明白了，剩下是墙皮、电线和吊顶

---

# 17) 你这个研究对 OpenClaw 最值得抄的，不是某一个函数，而是 8 个原则

最后给你一版真正值钱的提炼。  
如果要把 Claude Code 的精华迁移到 OpenClaw/你自己的 clean-room 实现，优先抄这 8 条：

1. **Prompt 不是常量，而是编译产物**
2. **prompt 必须静/动态分边界缓存**
3. **`CLAUDE.md` 这种规则系统要支持层级、局部路径命中、include**
4. **memory 要分“指令记忆 / 回忆记忆 / 蒸馏维护”三层**
5. **tool loop 必须显式状态机化，continuation/terminal 都要类型化**
6. **错误恢复优先内消化，别把半路错误裸扔给用户**
7. **turn 后处理（extract/dream/cleanup）要当一等公民**
8. **长期代理能力要单独抽成 runtime 层，而不是散落工具堆里**

这 8 条，比照抄某个 prompt 文本更有用。

---

如果你下一步要我做事，我建议直接进入产物阶段，不再纯口头分析：

1. 生成 `ClaudeCode_Architecture_Summary.md`
2. 生成 `ClaudeCode_BestPractices_for_OpenClaw.md`
3. 单独整理一份  
   `KAIROS_BuddySystem_Implementation_Guide.md`
4. 再补一个  
   `ClaudeCode_Prompt_Memory_Query_Pipeline.md`

这四份一做，你这轮研究就从“理解”变成“可复用资产”了。
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "9376",
  "sender_id": "1690419247",
  "sender": "小耗子",
  "timestamp": "Fri 2026-04-10 00:48 GMT+8"
}
```

Sender (untrusted metadata):
```json
{
  "label": "小耗子 (1690419247)",
  "id": "1690419247",
  "name": "小耗子",
  "username": "a2991495215"
}
```

继续
assistant: 继续。这轮不空聊了，我直接开始把研究沉淀成文档产物。
user: System (untrusted): [2026-04-10 00:49:16 GMT+8] Exec completed (tidy-ott, code 0)

Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.
When reading HEARTBEAT.md, use workspace file K:/openclaw-workspace/HEARTBEAT.md (exact case). Do not read docs/heartbeat.md.
Current time: Friday, April 10th, 2026 - 00:50 (Asia/Shanghai) / 2026-04-09 16:50 UTC
assistant: 做一次轻量心跳巡检：根目录、cron、OpenClaw 状态。
assistant: `openclaw status` 还没回，我补看一下已有输出。
assistant: [[reply_to_current]] 还是不能回 `HEARTBEAT_OK`。

- 持续高危项按历史结论未解除：`channels.telegram.groupPolicy="open"`，主 agent 仍是 `exec security=full`。  
- 当前轻量巡检正常：
  - `K:\openclaw-workspace` 根目录无新乱文件；
  - cron 正常，已启用，当前有 2 个 job；
- `openclaw status` 这次卡住没吐输出，暂时只能记为“状态命令未返回”，不能据此判断服务异常。
user: [Queued messages while agent was busy]

---
Queued #1
Conversation info (untrusted metadata):
```json
{
  "message_id": "9380",
  "sender_id": "1690419247",
  "sender": "小耗子",
  "timestamp": "Fri 2026-04-10 00:51 GMT+8"
}
```

Sender (untrusted metadata):
```json
{
  "label": "小耗子 (1690419247)",
  "id": "1690419247",
  "name": "小耗子",
  "username": "a2991495215"
}
```

压缩一下上下文
assistant: [[reply_to_current]] 行，我给你做一版**可直接接着干的压缩上下文**，把废枝全砍掉。

---

# 当前任务压缩版

## 目标
继续逆向分析：

- `K:\openclaw-workspace\Project\claude-code-mirror`  
重点吃透：
- 整体架构
- prompt 编译链
- query 主循环
- tool loop / tool_result 回填
- memory 系统
- KAIROS / proactive / dream / cron / brief
- 隐藏能力与 feature gate

并区分：
- `claude-code-mirror` = TypeScript 主研究样本
- `claw-code` = Rust clean-room 重写参考

---

# 已确认的主结构

## 1. 总架构分 5 层
1. **Prompt 编译层**
2. **输入预处理层**
3. **单轮执行引擎**
4. **会话编排层**
5. **后台维护层**

---

## 2. 关键分工
### `src/QueryEngine.ts`
负责：
- session 状态
- transcript 持久化
- app state / usage / file cache
- system prompt parts 获取
- 调 `query(...)`

### `src/query.ts`
负责：
- 真正 agent loop
- streaming
- tool_use / tool_result
- compact / recovery
- stop hooks
- continuation / terminal 状态机

**一句话：**
- `QueryEngine` = 会话壳
- `query.ts` = 单轮执行引擎

---

# Prompt 系统结论

## 3. 默认 prompt 底座
主文件：
- `src/constants/prompts.ts`

默认 prompt 不是单字符串，而是 section 编译系统，含：
- intro
- system
- doing tasks
- actions with care
- tools guidance
- tone/style
- output efficiency
- dynamic sections
- memory
- env
- language
- MCP
- scratchpad
- KAIROS/Brief/proactive section

---

## 4. Prompt 有静/动态边界
常量：
- `SYSTEM_PROMPT_DYNAMIC_BOUNDARY`

含义：
- 边界前：静态、可全局缓存
- 边界后：用户/项目/会话相关动态内容

**结论：**
Claude Code 的 prompt cache 是分段缓存，不是整段缓存。

---

## 5. Prompt section 默认缓存
主文件：
- `src/constants/systemPromptSections.ts`

- `systemPromptSection(...)` = 默认缓存
- `DANGEROUS_uncachedSystemPromptSection(...)` = 每轮重算，打断 cache

---

## 6. system prompt 真正拼装点
主文件：
- `src/QueryEngine.ts`

调用：
- `fetchSystemPromptParts(...)`

拿到：
- `defaultSystemPrompt`
- `userContext`
- `systemContext`

最终拼成：
- default/custom prompt
- memory mechanics prompt（某些 SDK/cowork 场景）
- appendSystemPrompt

---

# Memory 系统结论

## 7. memory 不是一条线，是三层
### A. 指令记忆层
- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `.claude/rules/*.md`
- `CLAUDE.local.md`

### B. 回忆记忆层
- AutoMem
- TeamMem
- `MEMORY.md`
- relevant memory recall

### C. 蒸馏维护层
- extract memories
- autoDream
- daily logs
- dream consolidation

---

## 8. `claudemd.ts` 是显式指令系统核心
主文件：
- `src/utils/claudemd.ts`

已确认：
- Managed / User / Project / Local 四层
- 从 cwd 向 root 逐级发现
- `.claude/rules/*.md` 支持无条件规则与条件规则
- frontmatter `paths` → `globs`
- `@include` 支持相对/绝对/home 路径
- include 有循环防护、深度限制、文本白名单
- external include 有 warning/approval 机制

---

## 9. 条件规则是真正按 targetPath 动态命中
函数：
- `processConditionedMdRules(...)`

结论：
- `.claude/rules/*.md` 可以变成 scoped instruction system
- 不是全局乱塞 prompt

---

## 10. relevant memory recall 已坐实
主文件：
- `src/memdir/findRelevantMemories.ts`

流程：
- scan memory headers
- build manifest
- sideQuery 让 Sonnet 选最相关文件
- 最多 5 个
- 排除 `MEMORY.md`
- 返回 path + `mtimeMs`

**结论：**
不是简单 semantic search，而是 manifest + LLM selector 精筛。

---

## 11. AutoMem 路径机制
主文件：
- `src/memdir/paths.ts`

已确认：
- 默认自动记忆开启（除非 env/settings/remote 条件关闭）
- 路径优先级：
  1. `CLAUDE_COWORK_MEMORY_PATH_OVERRIDE`
  2. settings `autoMemoryDirectory`
  3. `<memoryBase>/projects/<sanitized-git-root>/memory/`
- canonical git root 用于 worktree 共享记忆

---

## 12. KAIROS 的 daily log / dream 注释已坐实
`paths.ts` 注释明确写过：
- assistant mode 先写 daily log
- nightly `/dream` 蒸馏进 topic files + `MEMORY.md`

---

# Query / Tool Loop 结论

## 13. query 是状态机
主文件：
- `src/query/transitions.ts`

### Continue reason
- `tool_use`
- `reactive_compact_retry`
- `max_output_tokens_recovery`
- `max_output_tokens_escalate`
- `collapse_drain_retry`
- `stop_hook_blocking`
- `token_budget_continuation`
- `queued_command`

### Terminal reason
- `completed`
- `blocking_limit`
- `image_error`
- `model_error`
- `aborted_streaming`
- `aborted_tools`
- `prompt_too_long`
- `stop_hook_prevented`
- `hook_stopped`
- `max_turns`

---

## 14. tool loop 真正逻辑
主文件：
- `src/query.ts`

流程：
1. 模型流式输出 assistant message
2. 收集 `tool_use`
3. 执行工具（`runTools` / `StreamingToolExecutor`）
4. 生成 `tool_result`
5. 追加回消息流
6. 下一轮继续 query

**结论：**
Claude Code 是标准 assistant → tool → assistant agent trajectory。

---

## 15. recovery 机制很重
已确认支持：
- prompt-too-long → collapse drain / reactive compact
- max_output_tokens → escalate / resume meta message
- fallback model retry
- media/image 错误恢复
- stop hook blocking continuation
- token budget continuation

---

## 16. stop hooks 是 turn 后处理总线
主文件：
- `src/query/stopHooks.ts`

已确认可能触发：
- prompt suggestion
- template/job classify
- extractMemories
- executeAutoDream
- cleanupComputerUseAfterTurn

---

# KAIROS / Proactive 结论

## 17. KAIROS 不是单工具，是长期自治代理层
已确认组件：
- `SendUserMessage` / Brief
- `Sleep`
- `ScheduleCronTool`
- `RemoteTriggerTool`
- daily logs
- dream / consolidation
- tick-driven proactive mode

---

## 18. `BriefTool` 的真实定位
主文件：
- `src/tools/BriefTool/BriefTool.ts`
- `src/tools/BriefTool/prompt.ts`

结论：
- 真正给用户看的主要消息通道
- `status: normal | proactive`
- 支持 attachments
- KAIROS/assistant 模式下是主输出机制之一

---

## 19. `SleepTool`
主文件：
- `src/tools/SleepTool/prompt.ts`

结论：
- 用于 tick 间睡眠
- 替代 shell sleep
- 无事可做时必须 sleep
- 要平衡 API cost 和 5 分钟 prompt cache expiry

---

## 20. `CronCreateTool`
主文件：
- `src/tools/ScheduleCronTool/CronCreateTool.ts`
- `src/tools/ScheduleCronTool/prompt.ts`

结论：
- 支持 one-shot / recurring
- `durable: true` 可落盘到 `.claude/scheduled_tasks.json`
- session-only 任务默认不落盘
- 最多 50 jobs
- recurring 有最大生存期
- prompt 里明确要求尽量避开 `:00` / `:30` 扎堆

---

## 21. `RemoteTriggerTool`
主文件：
- `src/tools/RemoteTriggerTool/RemoteTriggerTool.ts`

结论：
- 是组织级/远程触发器管理面
- 走 API `/v1/code/triggers`
- 支持 list/get/create/update/run
- 依赖 OAuth token + org UUID + beta header

---

## 22. proactive / KAIROS prompt 真约束
主文件：
- `src/constants/prompts.ts`

`getProactiveSection()` 已确认：
- tick 机制
- 首次 tick 先问用户要做什么
- 后续 tick 主动找事做
- 没事必须 sleep
- focused / unfocused 影响自治程度
- brief section 可能内嵌进 proactive prompt

**结论：**
KAIROS = Claude Code 的长期自治代理模式。

---

# Dream / AutoDream 结论

## 23. autoDream 是 forked subagent
主文件：
- `src/services/autoDream/autoDream.ts`

已确认：
- time gate
- session gate
- consolidation lock
- 作为后台 forked agent 执行
- 独立 task 状态

默认阈值：
- 24 小时
- 5 个 session

---

## 24. KAIROS active 时不用通用 autoDream
`autoDream.ts` 明确：
- `getKairosActive() => false // KAIROS mode uses disk-skill dream`

所以：
- 普通模式 → autoDream
- KAIROS 模式 → 另一套更专门的 dream 路径

---

## 25. dream prompt 已坐实四阶段
主文件：
- `src/services/autoDream/consolidationPrompt.ts`

阶段：
1. Orient
2. Gather recent signal
3. Consolidate
4. Prune and index

目标不是摘要，而是：
- 合并
- 去重
- 纠错
- 更新索引
- 压缩 entrypoint
- 把相对日期转绝对日期

---

## 26. DreamTask 是正式后台任务 UI
主文件：
- `src/tasks/DreamTask/DreamTask.ts`

状态包含：
- `phase`
- `sessionsReviewing`
- `filesTouched`
- `turns`
- kill / fail / complete
- rollback lock

---

## 27. consolidation lock 设计
主文件：
- `src/services/autoDream/consolidationLock.ts`

- lock file body = PID
- lock file mtime = lastConsolidatedAt

这设计很漂亮，一文件两用。

---

# Buddy / Hidden 特性结论

## 28. Buddy 不是 runtime 核心，是 UI companion
主文件：
- `src/buddy/companion.ts`
- `src/buddy/prompt.ts`
- `src/buddy/types.ts`

结论：
- Buddy 是输入框旁的小 companion/watcher
- 不是主 query engine
- 不是 memory manager
- 更像 companion persona/UI system

---

## 29. internal gating / anti-leak 现象明显
已确认：
- 大量 `feature('X') ? require(...) : null`
- Undercover 模式抹掉 model name / model id
- 某些字符串会 runtime construct，避免 bundle 中出现敏感字面量

**结论：**
Claude Code 存在明确的 anti-leak / anti-distillation / internal-only slicing 策略。

---

# 当前最稳的总判断

Claude Code 核心不是一个 prompt，也不是一个 query loop。  
它是：

## Prompt 编译器
+  
## 状态机式 query runtime
+  
## 三层 memory system
+  
## turn 后处理总线
+  
## 长期自治代理层（KAIROS）

---

# 下一步最该做什么
别继续口头滚上下文了，直接进入产物化：

建议生成这 5 份文档：

1. `ClaudeCode_Architecture_Summary.md`
2. `ClaudeCode_BestPractices_for_OpenClaw.md`
3. `ClaudeCode_Prompt_Memory_Query_Pipeline.md`
4. `KAIROS_BuddySystem_Implementation_Guide.md`
5. `ClaudeCode_SystemPrompt_Extracted.txt`

---

# 如果你开新会话，可直接贴这段作为开场
**继续基于以下已确认结论，直接进入文档产出阶段，不再重复基础逆向：**

- `QueryEngine.ts` = 会话编排壳；`query.ts` = 单轮执行引擎
- 默认 prompt 底座在 `src/constants/prompts.ts`
- prompt 采用 section 编译 + 静/动态边界缓存
- `claudemd.ts` 实现 Managed/User/Project/Local memory 发现链
- `.claude/rules/*.md` 支持 frontmatter paths 条件命中
- AutoMem / TeamMem / relevant memory recall 已坐实
- stop hooks 会触发 extract memories / autoDream / cleanup
- KAIROS 是长期自治代理层，不是单工具
- autoDream 是 forked subagent，dream prompt 四阶段已读透
- Buddy 是 UI companion，不是 runtime 核心
- 现在直接写文档产物，不再重复底层扫描

---

如果你要，我下一条就直接开始替你**落盘写这 5 份文档**。
assistant: 行，我给你做一版**可直接接着干的压缩上下文**，把废枝全砍掉。

---

# 当前任务压缩版

## 目标
继续逆向分析：

- `K:\openclaw-workspace\Project\claude-code-mirror`
重点吃透：
- 整体架构
- prompt 编译链
- query 主循环
- tool loop / tool_result 回填
- memory 系统
- KAIROS / proactive / dream / cron / brief
- 隐藏能力与 feature gate

并区分：
- `claude-code-mirror` = TypeScript 主研究样本
- `claw-code` = Rust clean-room 重写参考

---

# 已确认的主结构

## 1. 总架构分 5 层
1. **Prompt 编译层**
2. **输入预处理层**
3. **单轮执行引擎**
4. **会话编排层**
5. **后台维护层**

---

## 2. 关键分工
### `src/QueryEngine.ts`
负责：
- session 状态
- transcript 持久化
- app state / usage / file cache
- system prompt parts 获取
- 调 `query(...)`

### `src/query.ts`
负责：
- 真正 agent loop
- streaming
- tool_use / tool_result
- compact / recovery
- stop hooks
- continuation / terminal 状态机

**一句话：**
- `QueryEngine` = 会话壳
- `query.ts` = 单轮执行引擎

---

# Prompt 系统结论

## 3. 默认 prompt 底座
主文件：
- `src/constants/prompts.ts`

默认 prompt 不是单字符串，而是 section 编译系统，含：
- intro
- system
- doing tasks
- actions with care
- tools guidance
- tone/style
- output efficiency
- dynamic sections
- memory
- env
- language
- MCP
- scratchpad
- KAIROS/Brief/proactive section

---

## 4. Prompt 有静/动态边界
常量：
- `SYSTEM_PROMPT_DYNAMIC_BOUNDARY`

含义：
- 边界前：静态、可全局缓存
- 边界后：用户/项目/会话相关动态内容

**结论：**
Claude Code 的 prompt cache 是分段缓存，不是整段缓存。

---

## 5. Prompt section 默认缓存
主文件：
- `src/constants/systemPromptSections.ts`

- `systemPromptSection(...)` = 默认缓存
- `DANGEROUS_uncachedSystemPromptSection(...)` = 每轮重算，打断 cache

---

## 6. system prompt 真正拼装点
主文件：
- `src/QueryEngine.ts`

调用：
- `fetchSystemPromptParts(...)`

拿到：
- `defaultSystemPrompt`
- `userContext`
- `systemContext`

最终拼成：
- default/custom prompt
- memory mechanics prompt（某些 SDK/cowork 场景）
- appendSystemPrompt

---

# Memory 系统结论

## 7. memory 不是一条线，是三层
### A. 指令记忆层
- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `.claude/rules/*.md`
- `CLAUDE.local.md`

### B. 回忆记忆层
- AutoMem
- TeamMem
- `MEMORY.md`
- relevant memory recall

### C. 蒸馏维护层
- extract memories
- autoDream
- daily logs
- dream consolidation

---

## 8. `claudemd.ts` 是显式指令系统核心
主文件：
- `src/utils/claudemd.ts`

已确认：
- Managed / User / Project / Local 四层
- 从 cwd 向 root 逐级发现
- `.claude/rules/*.md` 支持无条件规则与条件规则
- frontmatter `paths` → `globs`
- `@include` 支持相对/绝对/home 路径
- include 有循环防护、深度限制、文本白名单
- external include 有 warning/approval 机制

---

## 9. 条件规则是真正按 targetPath 动态命中
函数：
- `processConditionedMdRules(...)`

结论：
- `.claude/rules/*.md` 可以变成 scoped instruction system
- 不是全局乱塞 prompt

---

## 10. relevant memory recall 已坐实
主文件：
- `src/memdir/findRelevantMemories.ts`

流程：
- scan memory headers
- build manifest
- sideQuery 让 Sonnet 选最相关文件
- 最多 5 个
- 排除 `MEMORY.md`
- 返回 path + `mtimeMs`

**结论：**
不是简单 semantic search，而是 manifest + LLM selector 精筛。

---

## 11. AutoMem 路径机制
主文件：
- `src/memdir/paths.ts`

已确认：
- 默认自动记忆开启（除非 env/settings/remote 条件关闭）
- 路径优先级：
  1. `CLAUDE_COWORK_MEMORY_PATH_OVERRIDE`
  2. settings `autoMemoryDirectory`
  3. `<memoryBase>/projects/<sanitized-git-root>/memory/`
- canonical git root 用于 worktree 共享记忆

---

## 12. KAIROS 的 daily log / dream 注释已坐实
`paths.ts` 注释明确写过：
- assistant mode 先写 daily log
- nightly `/dream` 蒸馏进 topic files + `MEMORY.md`

---

# Query / Tool Loop 结论

## 13. query 是状态机
主文件：
- `src/query/transitions.ts`

### Continue reason
- `tool_use`
- `reactive_compact_retry`
- `max_output_tokens_recovery`
- `max_output_tokens_escalate`
- `collapse_drain_retry`
- `stop_hook_blocking`
- `token_budget_continuation`
- `queued_command`

### Terminal reason
- `completed`
- `blocking_limit`
- `image_error`
- `model_error`
- `aborted_streaming`
- `aborted_tools`
- `prompt_too_long`
- `stop_hook_prevented`
- `hook_stopped`
- `max_turns`

---

## 14. tool loop 真正逻辑
主文件：
- `src/query.ts`

流程：
1. 模型流式输出 assistant message
2. 收集 `tool_use`
3. 执行工具（`runTools` / `StreamingToolExecutor`）
4. 生成 `tool_result`
5. 追加回消息流
6. 下一轮继续 query

**结论：**
Claude Code 是标准 assistant → tool → assistant agent trajectory。

---

## 15. recovery 机制很重
已确认支持：
- prompt-too-long → collapse drain / reactive compact
- max_output_tokens → escalate / resume meta message
- fallback model retry
- media/image 错误恢复
- stop hook blocking continuation
- token budget continuation

---

## 16. stop hooks 是 turn 后处理总线
主文件：
- `src/query/stopHooks.ts`

已确认可能触发：
- prompt suggestion
- template/job classify
- extractMemories
- executeAutoDream
- cleanupComputerUseAfterTurn

---

# KAIROS / Proactive 结论

## 17. KAIROS 不是单工具，是长期自治代理层
已确认组件：
- `SendUserMessage` / Brief
- `Sleep`
- `ScheduleCronTool`
- `RemoteTriggerTool`
- daily logs
- dream / consolidation
- tick-driven proactive mode

---

## 18. `BriefTool` 的真实定位
主文件：
- `src/tools/BriefTool/BriefTool.ts`
- `src/tools/BriefTool/prompt.ts`

结论：
- 真正给用户看的主要消息通道
- `status: normal | proactive`
- 支持 attachments
- KAIROS/assistant 模式下是主输出机制之一

---

## 19. `SleepTool`
主文件：
- `src/tools/SleepTool/prompt.ts`

结论：
- 用于 tick 间睡眠
- 替代 shell sleep
- 无事可做时必须 sleep
- 要平衡 API cost 和 5 分钟 prompt cache expiry

---

## 20. `CronCreateTool`
主文件：
- `src/tools/ScheduleCronTool/CronCreateTool.ts`
- `src/tools/ScheduleCronTool/prompt.ts`

结论：
- 支持 one-shot / recurring
- `durable: true` 可落盘到 `.claude/scheduled_tasks.json`
- session-only 任务默认不落盘
- 最多 50 jobs
- recurring 有最大生存期
- prompt 里明确要求尽量避开 `:00` / `:30` 扎堆

---

## 21. `RemoteTriggerTool`
主文件：
- `src/tools/RemoteTriggerTool/RemoteTriggerTool.ts`

结论：
- 是组织级/远程触发器管理面
- 走 API `/v1/code/triggers`
- 支持 list/get/create/update/run
- 依赖 OAuth token + org UUID + beta header

---

## 22. proactive / KAIROS prompt 真约束
主文件：
- `src/constants/prompts.ts`

`getProactiveSection()` 已确认：
- tick 机制
- 首次 tick 先问用户要做什么
- 后续 tick 主动找事做
- 没事必须 sleep
- focused / unfocused 影响自治程度
- brief section 可能内嵌进 proactive prompt

**结论：**
KAIROS = Claude Code 的长期自治代理模式。

---

# Dream / AutoDream 结论

## 23. autoDream 是 forked subagent
主文件：
- `src/services/autoDream/autoDream.ts`

已确认：
- time gate
- session gate
- consolidation lock
- 作为后台 forked agent 执行
- 独立 task 状态

默认阈值：
- 24 小时
- 5 个 session

---

## 24. KAIROS active 时不用通用 autoDream
`autoDream.ts` 明确：
- `getKairosActive() => false // KAIROS mode uses disk-skill dream`

所以：
- 普通模式 → autoDream
- KAIROS 模式 → 另一套更专门的 dream 路径

---

## 25. dream prompt 已坐实四阶段
主文件：
- `src/services/autoDream/consolidationPrompt.ts`

阶段：
1. Orient
2. Gather recent signal
3. Consolidate
4. Prune and index

目标不是摘要，而是：
- 合并
- 去重
- 纠错
- 更新索引
- 压缩 entrypoint
- 把相对日期转绝对日期

---

## 26. DreamTask 是正式后台任务 UI
主文件：
- `src/tasks/DreamTask/DreamTask.ts`

状态包含：
- `phase`
- `sessionsReviewing`
- `filesTouched`
- `turns`
- kill / fail / complete
- rollback lock

---

## 27. consolidation lock 设计
主文件：
- `src/services/autoDream/consolidationLock.ts`

- lock file body = PID
- lock file mtime = lastConsolidatedAt

这设计很漂亮，一文件两用。

---

# Buddy / Hidden 特性结论

## 28. Buddy 不是 runtime 核心，是 UI companion
主文件：
- `src/buddy/companion.ts`
- `src/buddy/prompt.ts`
- `src/buddy/types.ts`

结论：
- Buddy 是输入框旁的小 companion/watcher
- 不是主 query engine
- 不是 memory manager
- 更像 companion persona/UI system

---

## 29. internal gating / anti-leak 现象明显
已确认：
- 大量 `feature('X') ? require(...) : null`
- Undercover 模式抹掉 model name / model id
- 某些字符串会 runtime construct，避免 bundle 中出现敏感字面量

**结论：**
Claude Code 存在明确的 anti-leak / anti-distillation / internal-only slicing 策略。

---

# 当前最稳的总判断

Claude Code 核心不是一个 prompt，也不是一个 query loop。
它是：

## Prompt 编译器
+
## 状态机式 query runtime
+
## 三层 memory system
+
## turn 后处理总线
+
## 长期自治代理层（KAIROS）

---

# 下一步最该做什么
别继续口头滚上下文了，直接进入产物化：

建议生成这 5 份文档：

1. `ClaudeCode_Architecture_Summary.md`
2. `ClaudeCode_BestPractices_for_OpenClaw.md`
3. `ClaudeCode_Prompt_Memory_Query_Pipeline.md`
4. `KAIROS_BuddySystem_Implementation_Guide.md`
5. `ClaudeCode_SystemPrompt_Extracted.txt`

---

# 如果你开新会话，可直接贴这段作为开场
**继续基于以下已确认结论，直接进入文档产出阶段，不再重复基础逆向：**

- `QueryEngine.ts` = 会话编排壳；`query.ts` = 单轮执行引擎
- 默认 prompt 底座在 `src/constants/prompts.ts`
- prompt 采用 section 编译 + 静/动态边界缓存
- `claudemd.ts` 实现 Managed/User/Project/Local memory 发现链
- `.claude/rules/*.md` 支持 frontmatter paths 条件命中
- AutoMem / TeamMem / relevant memory recall 已坐实
- stop hooks 会触发 extract memories / autoDream / cleanup
- KAIROS 是长期自治代理层，不是单工具
- autoDream 是 forked subagent，dream prompt 四阶段已读透
- Buddy 是 UI companion，不是 runtime 核心
- 现在直接写文档产物，不再重复底层扫描

---

如果你要，我下一条就直接开始替你**落盘写这 5 份文档**。
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "9386",
  "sender_id": "1690419247",
  "sender": "小耗子",
  "timestamp": "Fri 2026-04-10 00:56 GMT+8"
}
```

Sender (untrusted metadata):
```json
{
  "label": "小耗子 (1690419247)",
  "id": "1690419247",
  "name": "小耗子",
  "username": "a2991495215"
}
```

继续落盘
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "9395",
  "sender_id": "1690419247",
  "sender": "小耗子",
  "timestamp": "Fri 2026-04-10 01:00 GMT+8"
}
```

Sender (untrusted metadata):
```json
{
  "label": "小耗子 (1690419247)",
  "id": "1690419247",
  "name": "小耗子",
  "username": "a2991495215"
}
```

继续

