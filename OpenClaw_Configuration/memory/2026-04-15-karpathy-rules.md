# Session: 2026-04-15 10:33:30 UTC

- **Session Key**: agent:main:telegram:group:-1003957193295:topic:5
- **Session ID**: b6f074d0-8675-465c-a09f-16f4cff94c7e
- **Source**: telegram

## Conversation Summary

assistant: 查一下这个项目的定位、仓库和主要内容。
assistant: [[reply_to_current]] 这个项目本质上不是 Andrej Karpathy 亲自维护的“官方技能系统”，而是**社区把他关于 LLM 编程失误的观察，整理成一套可直接塞进 Claude Code / Cursor / VS Code 的行为规则**。

核心点就 4 条，很值钱，也很朴素：

1. **Think Before Coding**  
   别一上来瞎写。先讲清假设、歧义、取舍，不确定就问。

2. **Simplicity First**  
   只写够用的代码。别没事造抽象、加配置、加未来功能。

3. **Surgical Changes**  
   只改该改的地方。别顺手“优化”一堆无关代码，别搞扩散式重构。

4. **Goal-Driven Execution**  
   把任务变成可验证目标，最好用测试或明确检查标准闭环，不要靠“感觉差不多了”。

我查到的两个主要项目：

- **forrestchang/andrej-karpathy-skills**  
  最核心的那个仓库。基本就是把这些原则整理成一个 `CLAUDE.md`，给 Claude Code 用。  
  定位很明确：**减少 LLM 在编程时的瞎猜、过度设计、乱改代码、验证不足。**

- **mbeijen/andrej-karpathy-skills-cursor-vscode**  
  这是它的衍生版，做成了 **Cursor / VS Code 可安装规则扩展**。  
  不是新方法论，只是把同样那套规则换成编辑器更方便接入的形式。

我的判断很直接：  
**这项目的价值不在“技术实现”，而在“提示词工程的工程化落地”。**  
它火，是因为很多 AI 编程翻车点都被 Karpathy 说中了，而这套规则刚好能压住最常见的毛病。

如果你要一句话结论：  
**它不是一个复杂框架，而是一份高质量“驯化 coding agent”的行为宪法。**

如果你要，我下一步可以直接给你两样东西里的一个：

- **A.** 我把这套规则翻成中文，并改成更适合你现在 OpenClaw / Claude Code 工作流的版本  
- **B.** 我直接评估一下，看看这套东西适不适合并入你当前的 `AGENTS.md` / 个人工作流
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "330",
  "sender_id": "1690419247",
  "conversation_label": "辛的工作区 id:-1003957193295 topic:5",
  "sender": "小耗子",
  "timestamp": "Wed 2026-04-15 13:37 GMT+8",
  "group_subject": "辛的工作区",
  "topic_id": "5",
  "is_forum": true,
  "is_group_chat": true
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

整合优点，修改自己的配置文件。
assistant: 我把 Karpathy 那套里真正有用的部分并进你的工作规则，走最小改动，不搞花活。
assistant: [[reply_to_current]] 改好了。

这次我没把那套东西整包照抄，而是只并入了确实有用、且和你现有工作流不冲突的部分，已经写进：
- `/root/openclaw-workspace/AGENTS.md`

新增的核心约束是 4 组：
- **先澄清，再下手**
- **简单优先**
- **手术式修改**
- **目标驱动验证**

另外我也把这次变更记进了：
- `/root/openclaw-workspace/memory/2026-04-15.md`

结论很简单：以后我的默认执行风格会更少脑补、更少过度设计、改动更收敛、收尾更强调可验证。
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "333",
  "sender_id": "1690419247",
  "conversation_label": "辛的工作区 id:-1003957193295 topic:5",
  "sender": "小耗子",
  "timestamp": "Wed 2026-04-15 13:47 GMT+8",
  "group_subject": "辛的工作区",
  "topic_id": "5",
  "is_forum": true,
  "is_group_chat": true
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

你全部看完了吗？
assistant: [[reply_to_current]] 没有。

我**完整看了那个项目的核心说明和主规则文件**，也看了它的 **Cursor / VS Code 衍生版说明**，足够提炼方法论并改进我自己的规则；但我**没有逐页翻完它所有 issue、PR、commit、讨论串**。  
所以我刚才做的是：**基于核心内容完成有效整合**，不是装作把整个仓库每个角落都读烂了。

如果你问得更狠一点：  
**方法论我吃透了，仓库边角料我没全扫。**

如果你要，我可以下一步把它**整个仓库做一次彻底审阅**，包括：
- README / CLAUDE.md
- issues / PR 里有哪些实际争议点
- 社区后来补了哪些规则
- 哪些适合你，哪些不适合你
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "337",
  "sender_id": "1690419247",
  "conversation_label": "辛的工作区 id:-1003957193295 topic:5",
  "sender": "小耗子",
  "timestamp": "Wed 2026-04-15 14:08 GMT+8",
  "group_subject": "辛的工作区",
  "topic_id": "5",
  "is_forum": true,
  "is_group_chat": true
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

对的，完整的看一遍
assistant: 我把仓库和关键讨论都扫一遍，再给你一个能落地的结论，不报空话。
assistant: [[reply_to_current]] 看完了，至少**核心内容我已经完整扫过一遍**，不是只看个 README 在那装懂。

我这次实际看的范围是：

- 仓库定位与元数据
- `README.md`
- `CLAUDE.md`
- `EXAMPLES.md`
- `skills/karpathy-guidelines/SKILL.md`
- 仓库目录结构
- open issues / open PR 的前排内容
- 一个和你相关的实际问题：**“codex 怎么用”** 的 issue 回复

结论也更清楚了：

### 1. 这个仓库本体其实很小
真正的“方法论核心”就是那 4 条规则。  
剩下大头基本是：
- README 解释
- EXAMPLES 举反例和正例
- skill/plugin 适配包装
- 社区在讨论怎么迁移到 Cursor / Codex / `.cursorrules`

所以之前我提炼到你配置里的那 4 组，**确实抓住了主干**，不是抓偏了。

### 2. 最有价值的是 EXAMPLES，不是口号
README 只是讲理念。  
**EXAMPLES.md 才是真正把 Karpathy 那套落地的地方**：它反复在强调一件事——

> 很多 AI 写的代码不是“明显错”，而是**时机不对地引入复杂性**。

这点很关键。  
也就是说，问题往往不是它不会设计，而是它**太早设计**、**太爱顺手扩写**、**太容易把一个小任务做成中型工程**。

### 3. 社区现在的主要方向，不是改理念，而是做移植
我扫到的 open issues / PR，主流都在干这些事：

- 给 Cursor 加 `.cursorrules`
- 加 markdown lint / link check
- 问 Codex 怎么接入
- 其他编辑器怎么迁移

说明一件事：  
**核心原则已经比较稳定了，社区焦点在“怎么接到更多 agent / IDE 上”**，不是在大改方法论本身。

### 4. 你这边之前的整合，方向对，但还可以再精一点
我之前已经把核心 4 条并进 `/root/openclaw-workspace/AGENTS.md` 了。  
现在完整扫完后，我的判断是：

- **保留**：四大原则，没问题
- **可增强**：把 EXAMPLES 里最有杀伤力的“反模式提醒”再抽几条，压进我自己的执行规则里
- **没必要照搬**：它的安装说明、Claude plugin 包装、Cursor 兼容说明，对我这边价值不大

### 最终判断
这项目火，不是因为它“复杂”，恰恰是因为它**把 AI 编程最常见的蠢病讲得非常准，而且足够短，足够能执行**。  
它不是圣经，但确实是个好扳手。

如果你要，我下一步可以直接做两件事之一：

- **A.** 再次精修 `/root/openclaw-workspace/AGENTS.md`，把 EXAMPLES 里的高价值反模式也并进去  
- **B.** 不只改 `AGENTS.md`，顺手把 `SOUL.md / MEMORY.md` 的相关表述也统一一下，让整套人格和执行规则更一致
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "363",
  "sender_id": "1690419247",
  "conversation_label": "辛的工作区 id:-1003957193295 topic:5",
  "sender": "小耗子",
  "timestamp": "Wed 2026-04-15 18:16 GMT+8",
  "group_subject": "辛的工作区",
  "topic_id": "5",
  "is_forum": true,
  "is_group_chat": true
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

b
assistant: 我把这套规则顺手统一进人格和长期记忆，避免只改一处、前后打架。
assistant: [[reply_to_current]] 改完了，已经不是只改 `AGENTS.md` 那种半吊子整合。

这次我同步更新了：
- `/root/openclaw-workspace/SOUL.md`
- `/root/openclaw-workspace/MEMORY.md`

并补记到：
- `/root/openclaw-workspace/memory/2026-04-15.md`

现在统一进去的长期原则是这 4 个方向：
- **先澄清**：有歧义不脑补
- **简单优先**：默认最小可行解
- **最小改动**：避免顺手扩散修改
- **可验证结果**：不拿“看起来行”当完成

结论：现在这套约束已经从“操作手册”上升到“人格 + 长期记忆”，前后不会打架了。
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "379",
  "sender_id": "1690419247",
  "conversation_label": "辛的工作区 id:-1003957193295 topic:5",
  "sender": "小耗子",
  "timestamp": "Wed 2026-04-15 18:32 GMT+8",
  "group_subject": "辛的工作区",
  "topic_id": "5",
  "is_forum": true,
  "is_group_chat": true
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

应该改好了是吧
assistant: [[reply_to_current]] 是，已经改好并落盘了。

现在生效的文件是：
- `/root/openclaw-workspace/AGENTS.md`
- `/root/openclaw-workspace/SOUL.md`
- `/root/openclaw-workspace/MEMORY.md`

变更记录也写进了：
- `/root/openclaw-workspace/memory/2026-04-15.md`

现在这套 Karpathy 风格优点已经是我的默认工作方式，不是嘴上说说。


