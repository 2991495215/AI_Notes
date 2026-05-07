# Session: 2026-04-09 17:18:58 UTC

- **Session Key**: agent:main:main
- **Session ID**: 667629ed-1c79-4708-bea5-90d39c18238c
- **Source**: telegram

## Conversation Summary

user: A new session was started via /new or /reset. Run your Session Startup sequence - read the required files before responding to the user. Then greet the user in your configured persona, if one is provided. Be yourself - use your defined voice, mannerisms, and mood. Keep it to 1-3 sentences and ask what they want to do. If the runtime model differs from default_model in the system prompt, mention the default model. Do not mention internal steps, files, tools, or reasoning.
Current time: Friday, April 10th, 2026 - 01:11 (Asia/Shanghai) / 2026-04-09 17:11 UTC
assistant: [[reply_to_current]] 到位了。今天想狠狠干哪件事，直接丢给我——写、改、查、排障、自动化都行。
user: Conversation info (untrusted metadata):
```json
{
  "message_id": "9397",
  "sender_id": "1690419247",
  "sender": "小耗子",
  "timestamp": "Fri 2026-04-10 01:05 GMT+8"
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

你现在是一个 AI Agent 架构专家，专门研究 Claude Code 泄露事件中暴露的 harness engineering（AI 编码代理的工程脚手架）经验。

请基于以下公开分析项目和总结，帮助我系统学习 Claude Code 的核心架构优势，并提炼可复用的实用经验：

推荐学习资源（优先阅读这些，避免直接接触原始泄露源码）：
1. GitHub: ringmast4r/catyans-claude-code-source-analysis （逐模块架构解读）
2. GitHub: liuup/claude-code-analysis （架构、安全、Memory 机制分析）
3. 中文总结：《Claude Code 泄露真正有价值的 harness engineering 经验总结》（搜索 CSDN 或 gitcode）
4. 其他：Chachamaru127/claude-code-harness（实践型 harness 项目）、claw-code Python 重写版（干净室实现）
5. 相关文章：12 层渐进式工程包装、Agent Memory 系统（索引化+按需加载+清理）、上下文压缩、多代理协调、反蒸馏机制、卧底模式、系统提示词动态拼接等。

学习任务：
- 总结 Claude Code 的核心架构：最小 while-true Agent Loop + 多层 harness（权限、内存、工具、安全审查等）。
- 提炼 5-10 个最有价值的工程经验（例如：记忆系统设计、上下文管理、工具调用安全、提示词工程、Auto 模式等），并解释为什么这些比单纯提升模型参数更重要。
- 对于每个经验，给出如何在开源项目中复现或改进的建议（用 Python + LangChain/LlamaIndex 或类似框架）。
- 指出潜在风险（法律、道德、安全），并建议最佳学习实践方式。
- 最后，帮我设计一个小型开源 harness 原型计划（从简单 Agent Loop 开始，逐步添加记忆、工具、审查层）。

输出结构清晰，用 markdown 格式，分点说明，并附上关键代码片段示例（伪代码或简化实现）。重点帮助我把这些经验应用到自己的 AI 编码工具开发中。
assistant: 我先把公开分析资料抓一轮，再给你做成能落地的工程拆解，不讲虚的。
assistant: 直接搜挂了，我改走 GitHub 公开页面直抓，够用了。
assistant: 我换 raw 内容源，先拿 README 和目录线索，不碰乱七八糟的镜像。
assistant: [[reply_to_current]]下面我按**“架构 → 经验 → 复现 → 风险 → 原型路线”**给你拆。先说结论：Claude Code 真正值钱的地方，**不是某个神秘 prompt，也不是模型本身突然更聪明了**，而是把一个普通大模型包进了一套**工程化 harness**——权限、记忆、工具、审查、压缩、状态管理、多代理协作，全都做成了可控系统。

> 说明：我这轮尝试直接抓你列的公开仓库内容时，外部抓取被当前环境拦了，所以以下总结基于你给的学习方向、这些项目的公开讨论脉络，以及成熟 agent/harness 设计的共通模式来提炼；我不会假装自己逐行读完了那些仓库源码。

---

# 1. Claude Code 的核心架构到底强在哪

## 1.1 最核心：一个很小的 Agent Loop
底层其实可以抽象成一个很朴素的循环：

```python
while not done:
    context = build_context(state, memory, tool_results, files, policy)
    action = model(context)   # 输出文字 / tool call / finish
    result = execute_or_block(action, tools, permissions, safety)
    state = update_state(state, result)
```

单看这个 loop，没什么玄学。  
**真正的差距在 loop 外面那一圈圈 harness。**

---

## 1.2 多层 harness：把“会说话的模型”变成“可交付的编码代理”
可以把它理解成 12 层左右的工程包装：

1. **输入层**：用户请求、代码库状态、git 状态、工作目录
2. **上下文构建层**：系统提示词、任务目标、工具说明、当前文件摘要
3. **记忆层**：长期偏好、项目事实、最近操作轨迹
4. **规划层**：是否拆任务、是否进入 auto mode、是否调用子代理
5. **工具路由层**：shell、文件读写、搜索、diff、测试、浏览器等
6. **权限层**：哪些操作可直接做，哪些要确认
7. **审查层**：危险命令、外部请求、删除/覆盖、泄露风险
8. **执行层**：真正跑命令、编辑文件、收集输出
9. **压缩层**：长上下文摘要、失败日志提纯、关键信息保留
10. **恢复层**：崩了能续、工具超时能重试、会话能接着干
11. **协作层**：多 agent / 子任务分派 / review agent
12. **输出层**：给用户可解释、可审计、可中断的结果

**换句话说：模型只是“推理内核”，harness 才是“操作系统”。**

---

## 1.3 为什么这比单纯堆模型参数更重要
大模型参数更大，确实会提升：
- 代码理解
- 规划能力
- 指令跟随
- 容错性

但在真实编码场景里，真正限制效果的往往不是“不会写代码”，而是：

- 不知道**什么时候该读哪个文件**
- 不知道**哪些命令危险**
- 不知道**历史上下文什么该保留**
- 不知道**失败后怎么恢复**
- 不知道**什么时候该停下来问人**
- 不知道**如何在长任务里不迷路**

这些都不是参数规模直接解决的，**这是系统工程问题**。

---

# 2. Claude Code 最值得学的 8 个 harness engineering 经验

---

## 经验 1：把 Agent 做成“最小循环 + 外挂能力”，不要把复杂性塞进 prompt

### 核心思想
不要试图用一个几千行 system prompt 解决所有问题。  
正确做法是：

- loop 极简
- 复杂能力外置为模块
- prompt 只负责当前回合的行为约束
- 状态、权限、记忆、审查都由代码维护

### 为什么重要
因为 prompt 是**软约束**，代码是**硬约束**。  
你靠 prompt 告诉模型“不要删文件”，它照样可能删；  
你在执行层强制拦截 `rm -rf`，它就真删不了。

### 开源复现建议
用 Python 把系统拆成：

- `agent_loop.py`
- `context_builder.py`
- `tool_router.py`
- `policy_engine.py`
- `memory_store.py`
- `task_state.py`

### 简化实现
```python
class Agent:
    def __init__(self, llm, tools, policy, memory):
        self.llm = llm
        self.tools = tools
        self.policy = policy
        self.memory = memory

    def run(self, user_goal):
        state = {"goal": user_goal, "done": False, "history": []}

        while not state["done"]:
            prompt = build_prompt(state, self.memory)
            action = self.llm.invoke(prompt)

            if action["type"] == "finish":
                state["done"] = True
                return action["message"]

            if action["type"] == "tool_call":
                check = self.policy.check(action)
                if not check.allowed:
                    state["history"].append({"blocked": check.reason})
                    continue

                result = self.tools.execute(action)
                state["history"].append({"tool_result": result})
```

### 用 LangChain/LlamaIndex 怎么做
- LangChain：用 Runnable / AgentExecutor 做 loop 外壳，但别完全依赖它默认 agent 行为
- LlamaIndex：更适合做 memory/index/query 层
- 最稳妥：**自己写 loop，框架只当零件库**

---

## 经验 2：记忆系统不是“把聊天全塞进去”，而是“索引化 + 按需加载 + 定期清理”

### 核心思想
Memory 不是越多越好，而是：
- 分层
- 可检索
- 可裁剪
- 可审计

建议分 4 层：

1. **会话短期记忆**：当前任务状态
2. **项目记忆**：代码库结构、约定、常见命令
3. **用户偏好记忆**：风格、禁忌、默认选项
4. **长期经验记忆**：失败模式、修复套路、最佳实践

### 为什么重要
绝大多数 agent 失败，不是因为它不会推理，而是因为：
- 上下文装太多，注意力稀释
- 旧信息污染新任务
- 无法找到前面真正关键的 3 行结论

### 开源复现建议
用“结构化记忆 + 向量检索 + TTL/清理策略”。

#### 推荐组合
- 文本存储：SQLite / Postgres
- 向量库：FAISS / Chroma / pgvector
- 索引框架：LlamaIndex 很适合

### 简化数据结构
```python
from dataclasses import dataclass
from datetime import datetime

@dataclass
class MemoryItem:
    kind: str          # preference/project_fact/error_pattern/task_summary
    content: str
    tags: list[str]
    created_at: datetime
    score: float = 1.0
    expires_at: datetime | None = None
```

### 检索逻辑
```python
def retrieve_memory(query, store, top_k=5):
    candidates = store.semantic_search(query, top_k=20)
    filtered = [
        x for x in candidates
        if x.kind in ["project_fact", "preference", "error_pattern"]
    ]
    return rerank(filtered, query)[:top_k]
```

### 改进点
别只做向量检索，最好加：
- 标签过滤
- 时间衰减
- source trace
- “是否已失效”标记

**一句话：记忆系统要像知识库，不要像垃圾场。**

---

## 经验 3：上下文管理的关键不是“更长”，而是“更有层级”

### 核心思想
上下文不是一个大包，而应该是：

- 固定层：系统规则、权限、工具说明
- 任务层：当前目标、计划、最近结果
- 代码层：当前相关文件、diff、测试输出
- 记忆层：检索出来的必要事实
- 压缩层：旧轮次摘要

### 为什么重要
真实开发任务里，token 浪费主要发生在：
- 重复放工具说明
- 重复放大段日志
- 把不相关文件全塞进去
- 把历史对话原样堆到尾部

### 开源复现建议
做一个 `ContextAssembler`：

```python
class ContextAssembler:
    def build(self, task, state, memory_hits, file_snippets, tool_results):
        return {
            "system_rules": load_system_rules(),
            "task_goal": task.goal,
            "active_plan": state.get("plan"),
            "recent_actions": summarize_actions(state["history"][-8:]),
            "memory_hits": memory_hits[:5],
            "file_snippets": rank_relevant_snippets(file_snippets)[:8],
            "tool_results": compact_tool_results(tool_results),
        }
```

### 改进点
加入 3 种压缩：
1. **日志压缩**：保留错误栈头尾
2. **对话压缩**：保留决策，不保留寒暄
3. **代码压缩**：只保留相关函数/类，不塞整文件

### 这比换更强模型更值钱的原因
因为再强的模型，也不该拿注意力去读 300 行没用日志。

---

## 经验 4：工具调用必须经过“策略引擎”，不能直接裸连 shell

### 核心思想
工具调用不是“模型说执行就执行”，而是：

`模型提议 -> 策略判定 -> 必要时确认 -> 执行 -> 结果回流`

### 为什么重要
因为编码代理最危险的地方，不是写错代码，而是：
- 删除文件
- 覆盖配置
- 发网请求泄露 secret
- 执行不明脚本
- git reset / force push

### 最小策略模型
```python
DANGEROUS_PATTERNS = [
    "rm -rf",
    "del /s /q",
    "format ",
    "shutdown",
    "git reset --hard",
    "git clean -fd",
]

def check_command(cmd: str):
    for p in DANGEROUS_PATTERNS:
        if p in cmd.lower():
            return {"allowed": False, "reason": f"dangerous pattern: {p}"}
    return {"allowed": True}
```

### 更好的做法：分级权限
- **allow**：读文件、列目录、跑测试
- **ask**：安装包、改配置、写文件
- **deny**：删系统目录、发未知外网、读 secrets

### LangChain/LangGraph 实现建议
把 policy engine 做成单独节点：

```python
graph:
user -> planner -> policy_check -> tool_exec -> summarize -> user
```

### 改进点
加上：
- 命令白名单 / 黑名单
- 工作目录隔离
- 环境变量脱敏
- 出网域名 allowlist
- 审计日志

---

## 经验 5：Auto 模式的本质不是“全自动”，而是“可持续地少打扰”

### 核心思想
真正好用的 Auto 模式不是一路无脑执行，而是：

- 低风险动作自动做
- 高风险动作停下来
- 长流程自动续跑
- 关键分叉点再问用户

### 为什么重要
用户讨厌两种极端：
1. 啥都问——像个废物
2. 啥都自己干——像个定时炸弹

### 开源复现建议
做一个风险分级器：

```python
def risk_level(action):
    if action["type"] == "read_file":
        return "low"
    if action["type"] == "write_file":
        return "medium"
    if action["type"] == "shell" and "pip install" in action["command"]:
        return "medium"
    if action["type"] == "shell" and "rm -rf" in action["command"]:
        return "high"
    return "medium"
```

```python
def should_ask_user(action, auto_mode=True):
    level = risk_level(action)
    if level == "high":
        return True
    if level == "medium" and not auto_mode:
        return True
    return False
```

### 改进建议
给 Auto 模式做 3 档：
- `manual`
- `semi-auto`
- `auto-safe`

这比“开/关”二元开关好用太多。

---

## 经验 6：系统提示词不是一整块圣经，而应该动态拼接

### 核心思想
Prompt 不该是一个固定几千行字符串。  
应该由模块拼接：

- 基础人格/角色
- 当前任务规则
- 工具使用约束
- 当前工作区事实
- 用户偏好
- 风险控制提醒
- 当前模式（review / code / debug）

### 为什么重要
不同任务需要不同约束。  
调试模式和写文档模式需要的行为规范不一样。

### 伪代码
```python
def build_system_prompt(mode, user_prefs, tool_policies, task_meta):
    blocks = [
        BASE_IDENTITY_PROMPT,
        MODE_PROMPTS[mode],
        render_user_prefs(user_prefs),
        render_tool_rules(tool_policies),
        render_task_rules(task_meta),
    ]
    return "\n\n".join(x for x in blocks if x)
```

### 改进建议
不要把所有“历史教训”全拼进去，只拼：
- 当前任务相关的
- 最近失败模式相关的
- 当前可用工具相关的

### 反蒸馏 / 卧底模式的工程意义
这些设计本质上是在做：
- 降低 prompt 被完整抄走后的可复用性
- 降低对手从单一静态提示里逆向全部行为规则

真正有价值的不是“藏 prompt”，而是**行为逻辑在代码里，prompt 只是一层接口**。

---

## 经验 7：多代理不是越多越强，而是只在“认知隔离”有价值时才用

### 核心思想
多 agent 真正有价值的场景：

- 规划 agent：拆任务
- 执行 agent：改代码/跑命令
- 审查 agent：看风险/看 diff
- 记忆 agent：整理沉淀
- research agent：查资料

### 为什么重要
单 agent 容易：
- 一边做一边忘
- 自己写自己吹
- 计划和执行互相污染

### 最小多代理模式
```python
planner_output = planner.run(task)
executor_output = executor.run(planner_output["subtask"])
review_output = reviewer.run({
    "plan": planner_output,
    "result": executor_output
})
```

### 开源实现建议
初期别上复杂多代理框架。  
先做**串行角色链**：

1. Planner
2. Executor
3. Reviewer

够用了。

### 什么时候别用多代理
- 小任务
- 上下文很短
- 工具链简单
- 延迟敏感

多代理不是银弹，滥用只会让 token 和复杂度爆炸。

---

## 经验 8：失败恢复、轨迹记录、可审计性，比“单次最优回答”更重要

### 核心思想
工程系统的强弱，不看它最顺的时候多聪明，  
看它失败时是不是还能：
- 知道做到哪了
- 知道为什么失败
- 能从中断点续跑
- 给用户可审计的记录

### 开源复现建议
给每个动作写 event log：

```python
@dataclass
class Event:
    step_id: str
    type: str      # model/tool/policy/error
    payload: dict
    timestamp: str
```

```python
def log_event(store, event_type, payload):
    store.append({
        "type": event_type,
        "payload": payload,
        "timestamp": now_iso(),
    })
```

### 最低限度要记录的东西
- 用户目标
- 当前计划
- 每次工具调用
- 被拦截原因
- 文件修改摘要
- 错误摘要
- 最终结果

### 为什么比更大模型更重要
因为真实用户不是只需要“这次答对”，而是需要：
- 下次还能继续
- 出事能追责
- 能复盘优化

---

# 3. 如何在开源项目里复现或改进

下面给你一个**Python 生态可落地路线**。

---

## 3.1 技术栈建议

### 轻量原型
- LLM 接入：OpenAI SDK / Anthropic SDK / LiteLLM
- Agent 编排：自己写 loop
- 工具层：Python functions + subprocess
- 存储：SQLite
- 向量检索：FAISS / Chroma

### 稍正式
- 编排：LangGraph
- Memory/Index：LlamaIndex
- 观测：OpenTelemetry / Langfuse / Helicone
- 权限策略：自定义 policy engine
- 前端：Textual / FastAPI + Web UI / Tauri

### 为什么我不建议你一开始全押 LangChain AgentExecutor
因为默认 agent 往往：
- 抽象过厚
- 难做强约束
- 不利于做审查和恢复
- 很难完全掌控上下文构造

**最佳实践：自己写 harness，框架只拿来做 memory/index/graph。**

---

## 3.2 一个推荐的目录结构

```text
harness/
├─ app.py
├─ core/
│  ├─ agent_loop.py
│  ├─ context_builder.py
│  ├─ prompt_builder.py
│  ├─ state_manager.py
│  └─ event_log.py
├─ tools/
│  ├─ shell_tool.py
│  ├─ file_tool.py
│  ├─ search_tool.py
│  └─ git_tool.py
├─ memory/
│  ├─ memory_store.py
│  ├─ retriever.py
│  └─ summarizer.py
├─ policy/
│  ├─ command_policy.py
│  ├─ file_policy.py
│  └─ network_policy.py
├─ agents/
│  ├─ planner.py
│  ├─ executor.py
│  └─ reviewer.py
└─ tests/
```

---

# 4. 一个小型 harness 的关键代码片段

---

## 4.1 最小 Agent Loop
```python
def run_agent(user_goal: str):
    state = init_state(user_goal)

    while True:
        ctx = context_builder(state)
        decision = llm_decide(ctx)

        if decision["type"] == "finish":
            return decision["final"]

        elif decision["type"] == "tool_call":
            policy = check_policy(decision)
            if not policy.allowed:
                state.history.append({
                    "blocked": policy.reason
                })
                continue

            result = execute_tool(decision)
            state.history.append({
                "action": decision,
                "result": compress_result(result),
            })

        elif decision["type"] == "ask_user":
            return decision["question"]
```

---

## 4.2 动态 Prompt Builder
```python
def build_prompt(state, memories, tool_schema):
    return f"""
你是一个编码代理。

# 当前目标
{state.goal}

# 当前计划
{state.plan}

# 最近结果
{state.recent_summary}

# 相关记忆
{format_memories(memories)}

# 可用工具
{tool_schema}

# 规则
- 优先读取相关文件后再修改
- 不要执行危险命令
- 不确定时先问
- 输出只允许三种类型：
  1. finish
  2. tool_call
  3. ask_user
""".strip()
```

---

## 4.3 记忆检索 + 清理
```python
def memory_pipeline(query, db):
    hits = db.semantic_search(query, top_k=30)
    hits = filter_invalid(hits)
    hits = apply_time_decay(hits)
    hits = deduplicate(hits)
    return hits[:6]

def cleanup_memory(db):
    for item in db.all():
        if item.kind == "ephemeral" and item.age_days > 7:
            db.delete(item.id)
        elif item.score < 0.15:
            db.archive(item.id)
```

---

## 4.4 工具审查层
```python
def execute_shell(command: str):
    check = command_policy(command)
    if not check["allowed"]:
        return {"blocked": True, "reason": check["reason"]}

    # 真正执行前做脱敏和 cwd 限制
    return run_subprocess(command, cwd=SAFE_WORKDIR)
```

---

## 4.5 Reviewer Agent
```python
def review_change(plan, diff, test_output):
    review_prompt = f"""
请审查以下改动：
# 计划
{plan}

# Diff
{diff}

# 测试输出
{test_output}

请回答：
1. 改动是否满足目标
2. 是否引入风险
3. 是否需要回滚或补测试
"""
    return reviewer_llm.invoke(review_prompt)
```

---

# 5. 潜在风险：这部分别装看不见

---

## 5.1 法律风险
如果你直接消费、传播、复刻泄露源码，风险包括：

- 版权侵权
- 商业秘密争议
- 条款违规
- 二次分发风险

### 建议
- 只学习**公开分析、clean-room 实现、抽象经验**
- 不直接拷贝泄露源码、提示词、私有逻辑
- 你的实现要能说明：**独立设计、独立编码、仅借鉴公开思想**

---

## 5.2 安全风险
编码代理最危险的是它真的能动系统：

- 执行 shell
- 改文件
- 发网请求
- 读环境变量
- 泄露 token / ssh key

### 建议
- 默认沙箱
- 默认 deny 出网
- secrets 脱敏
- 危险操作必须确认
- 全链路审计日志
- 每个工具都最小权限

---

## 5.3 道德风险
“卧底模式”“反蒸馏”这类话题很容易滑向灰区。

### 我的判断
能学的是：
- 降低 prompt 被静态复制后的复用性
- 把关键行为固化到代码和策略层
- 避免单点泄露暴露全部系统设计

不该学的是：
- 欺骗用户
- 绕过审计
- 隐藏高风险行为
- 刻意规避授权机制

---

# 6. 最佳学习实践：怎么学不跑偏

## 建议顺序
### 第 1 阶段：先学抽象，不碰泄露细节
看这些主题：
- 最小 agent loop
- tool calling
- policy engine
- memory retrieval
- context compression
- multi-agent review

### 第 2 阶段：看 clean-room / analysis 项目
重点看：
- 架构图
- 模块职责
- 状态流
- 工具边界
- memory 设计

### 第 3 阶段：自己做一个最小可运行原型
先别做全家桶。  
先做到：
- 能接收任务
- 能读文件
- 能提议修改
- 能跑测试
- 能审查危险命令

### 第 4 阶段：再加记忆和压缩
很多人一上来就 RAG、multi-agent、GUI，最后全烂。  
先保证 loop 稳，再加层。

---

# 7. 一个小型开源 harness 原型计划

下面给你一个**从 0 到能用**的路线。

---

## Phase 0：最小可跑版本（1-2 天）
### 目标
做出一个能完成简单 coding task 的 agent。

### 功能
- 用户输入任务
- LLM 生成 tool call
- 支持读文件 / 写文件 / 执行测试
- 风险命令拦截
- 最终返回摘要

### 产物
- CLI 程序
- JSON event log
- 最小 system prompt

### 成功标准
- 能在 demo repo 里修一个简单 bug
- 不会无脑执行危险命令

---

## Phase 1：加入任务状态和恢复（2-3 天）
### 功能
- 每步 action 落盘
- 中断后可恢复
- 自动压缩旧历史
- 输出执行摘要

### 关键模块
- `state_manager.py`
- `event_log.py`
- `recovery.py`

### 成功标准
- agent 中断后能从 step N 继续

---

## Phase 2：加入分层记忆（3-5 天）
### 功能
- 用户偏好记忆
- 项目事实记忆
- 错误修复记忆
- 向量检索 + 标签过滤

### 技术建议
- SQLite + FAISS
- LlamaIndex 管检索层

### 成功标准
- 第二次处理同项目时明显更快、更少废话

---

## Phase 3：加入 Reviewer（2-4 天）
### 功能
- executor 改代码
- reviewer 看 diff + test output
- 给出 pass / revise / ask_user

### 成功标准
- 低级错误率下降
- 能识别明显风险改动

---

## Phase 4：加入上下文压缩和模式切换（3-5 天）
### 功能
- debug / implement / review 三种 mode
- 动态 prompt 拼接
- 历史摘要
- 日志压缩

### 成功标准
- 长任务不明显漂移
- token 成本下降

---

## Phase 5：加入安全边界（持续）
### 功能
- sandbox
- network allowlist
- secret redaction
- destructive action confirmation
- audit trail

### 成功标准
- 你敢让它在真实项目里跑，而不是只敢 demo

---

# 8. 我建议你优先抄走的“真正有用的骨架”

如果只选最值钱的 5 个，优先是这几个：

1. **最小 loop，复杂性外置**
2. **记忆索引化，不要原样堆聊天记录**
3. **上下文分层 + 压缩**
4. **工具调用前置策略审查**
5. **planner / executor / reviewer 串行分工**

这 5 个一旦做对，你的 agent 即使用中等模型，也会比很多“拿最强模型硬怼”的玩具 agent 更稳、更像真工具。

---

# 9. 一个你可以直接开干的 MVP 规格

## 项目名
`cleanroom-code-harness`

## MVP 功能
- CLI 输入任务
- 支持 `read_file`, `write_file`, `run_command`
- 命令策略审查
- JSON event log
- SQLite memory
- reviewer 二次检查

## 第一版别做
- 浏览器
- 多代理并发
- 自动联网搜索
- GUI
- 花哨插件系统

## 第一版一定要做
- 可恢复
- 可审计
- 可拦截
- 可压缩
- 可扩展

---

如果你要，我下一步可以直接继续给你两样东西里的任意一个：

1. **一份完整的开源 harness 项目脚手架目录 + Python 文件模板**
2. **一版“Claude Code 风格”的 clean-room 最小实现代码**（可直接开始跑）
