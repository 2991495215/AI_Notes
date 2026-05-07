# Session: 2026-04-22 19:14:28 UTC

- **Session Key**: agent:main:telegram:group:-1003983469354:topic:3
- **Session ID**: 6abb065d-6847-430e-9d61-021b0f6c9051
- **Source**: telegram

## Conversation Summary

assistant: 我先做个可用性盘点：分成“平台原生工具”和“工作区里额外装的搜索 skill/脚本”，然后各跑一次最小探测。
assistant: 再直接测一下平台原生 `web_search` 和最简网页抓取这两条，确认是不是“自带能用，外装那堆半残”。
assistant: 结论：**现在“能稳定用”的搜索能力很少，主要是网页抓取能用；真正的“搜索”大多是半配置状态。**

我盘了一圈，当前大概是这样：

## 目前可用
### 1) `web_fetch`
- **状态：可用**
- 我已经直接测过：能正常抓 `https://docs.openclaw.ai`
- 适合：
  - 已知 URL 的网页内容读取
  - 拉文档、文章、页面正文
- 不适合：
  - 代替搜索引擎找新链接

## 目前不可用 / 未就绪
### 2) 平台原生 `web_search`
- **状态：不可用**
- 直接测试返回：
  - `missing_perplexity_api_key`
- 说明：
  - 这套现在依赖 **Perplexity / OpenRouter** 的 key
  - 当前环境里 **没配好 `PERPLEXITY_API_KEY`**（至少运行态没拿到）

### 3) `brave-web-search` skill
- **状态：不可用**
- 原因：
  - skill 文档明确要求 `BRAVE_SEARCH_API_KEY`
  - 我检查到：**`BRAVE_SEARCH_API_KEY=MISSING`**
- 结论：
  - 这套只是“装了说明书”，**没配凭证，跑不起来**

### 4) `tavily-search` skill
- **状态：半残，当前不可直接用**
- 现状：
  - `TAVILY_API_KEY` **有**
  - 但它依赖的 CLI：`tvly` **没装 / 不在 PATH**
- 结论：
  - **凭证有了，执行器没装好**
  - 属于最容易修复的一套

## 工作区里有，但本质上不是“现成可用搜索工具”
### 5) `multi-search-engine` skill
- **状态：可作为“手工拼搜索 URL 的说明”，但不算真正稳定搜索工具**
- 原因：
  - 它本质更像一份“搜索引擎 URL 模板手册”
  - 主要靠 `web_fetch` 去抓 Google / DuckDuckGo / Brave / 百度等搜索结果页
- 风险：
  - 搜索结果页经常有反爬、JS、地区限制、验证码
  - **能不能稳定抓到结构化结果，不靠谱**
- 结论：
  - 能当备胎，不适合当主力

### 6) `apify` / `playwright-scraper` / `youtube-watcher` / `summarize`
- **状态：不是通用搜索工具**
- 它们更偏：
  - Apify：跑 actor 抓站
  - Playwright：动态网页自动化
  - YouTube：视频转录/读取
  - Summarize：对已有 URL/文件做总结
- 不能算“我现在拿来就能稳定搜全网”的主搜索入口

---

## 现状一句话总结
你说得没错，**现在确实杂**：

- **能抓页面**：`web_fetch`
- **能真正搜索但现在挂着**：
  - `web_search` → 缺 Perplexity/OpenRouter key
  - `brave-web-search` → 缺 Brave key
  - `tavily-search` → 有 key，但缺 `tvly` CLI
- **像工具但其实更像资料/备胎**：
  - `multi-search-engine`

---

## 我建议怎么收口
优先级我给你排好了：

### 方案 A：只保留一套主搜索
**推荐选 Tavily**
原因：
- 你已经有 `TAVILY_API_KEY`
- 只差把 `tvly` 装好
- 比“抓搜索结果页”稳得多

### 方案 B：启用平台原生 `web_search`
前提：
- 配 `PERPLEXITY_API_KEY` 或 `OPENROUTER_API_KEY`
- 好处：
  - 直接走 OpenClaw 原生工具
  - 后续调用最统一

### 方案 C：清理杂物
建议把这些标成“非主力”：
- `brave-web-search`（没 key）
- `multi-search-engine`（仅备胎）
- 其他非通用搜索 skill

---

## 我给你的直接判断
**最值得修的是 `tavily-search`。**
因为它离可用最近：**key 已有，只差安装 CLI 并做一次验证**。

如果你要，我下一步可以直接做这两件事：
1. 把 **当前搜索能力清单**整理成一份简短表
2. **开始修 Tavily**，把它变成你现在能稳定用的主搜索入口

你回一句：
- **“修 Tavily”**
或
- **“整理并精简搜索工具”**

我就直接动手。
user: Conversation info (untrusted metadata):
```json
{
  "chat_id": "telegram:-1003983469354",
  "message_id": "869",
  "sender_id": "1690419247",
  "conversation_label": "斯蒂芬的工作区 id:-1003983469354 topic:3",
  "sender": "小耗子",
  "timestamp": "Wed 2026-04-22 04:19 GMT+8",
  "group_subject": "斯蒂芬的工作区",
  "topic_id": "3",
  "topic_name": "1",
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

修tavily，再整理其他的
assistant: 先把 Tavily 修通，再顺手把“搜索能力现状”整理成一份清单，后面好收口。
assistant: 直接跑 workspace 里那套 Node 版 Tavily，别跟没装的 `tvly` CLI 纠缠。先验证它能不能真出结果。
assistant: Tavily 已经被我跑通了。现在要做的是把“能用的这套”固定下来，别以后又误走到那份坏掉的 CLI 说明。
assistant: 我会把坏掉的那份用户态 Tavily skill 改成直接指向这套已验证可用的 Node 版实现，再补一份清单，后面你就知道哪些该留、哪些该废。
assistant: 再补一脚验证：确认用户态 skill 改完后内容正确，避免我改了个寂寞。
assistant: Tavily 我已经修通了，顺手把其他搜索能力也整理好了。

## 已完成
### 1) Tavily 修复
我确认了这台机子上：
- `TAVILY_API_KEY` **已存在**
- `tvly` CLI **没装**
- 但 **workspace 里自带的 Node 版 Tavily 脚本可以正常工作**

我实际跑通了这条：
```powershell
node K:\openclaw-workspace\skills\tavily-search\scripts\search.mjs "OpenClaw 官方文档" -n 3
```

结果正常返回了：
- `## Answer`
- `## Sources`

也就是说：**Tavily 现在已经可用**，而且不需要 `tvly login` 那套了。

### 2) 修正了坏掉的 Tavily skill 说明
我把原来那份会误导去装 `tvly` CLI 的用户态 skill 改了，路径是：

`C:\Users\a2832\.openclaw\skills\tavily-search\SKILL.md`

现在它已经改成：
- 明确走 **Node 脚本版**
- 不再要求 `tvly`
- 直接指向：
  - `K:\openclaw-workspace\skills\tavily-search\scripts\search.mjs`
  - `K:\openclaw-workspace\skills\tavily-search\scripts\extract.mjs`

## 其他搜索能力整理结果
我写了一份清单，路径在：

`K:\openclaw-workspace\notes\resources\search-tools-status-2026-04-22.md`

核心结论是：

### 现在建议保留为主力
- **Tavily（Node 版）**：可用，建议作为主搜索
- **web_fetch**：可用，但它是“抓已知 URL”，不是搜索引擎
- **playwright-scraper**：只在动态网页抓取时补位

### 当前不可用或不适合当主力
- **原生 `web_search`**：不可用，缺 `PERPLEXITY_API_KEY`
- **`brave-web-search`**：不可用，缺 `BRAVE_SEARCH_API_KEY`
- **`multi-search-engine`**：更像 URL 模板/备胎，不算稳定主搜索

## 我的判断
现在最合理的收口方式是：

**默认搜索 = Tavily**
**已知链接抓内容 = web_fetch**
**动态站点补刀 = playwright-scraper**

这样不杂，能打。

如果你要，我下一步可以继续做两件事里的一个：
1. **继续精简**：把 `brave-web-search` 这类没配置好的搜索入口标废或移走
2. **继续补全**：把原生 `web_search` 也修到可用（前提是你要配 Perplexity / OpenRouter 那套 key）

你回一句：
- **“继续精简”**
或
- **“把 web_search 也修了”**
user: Conversation info (untrusted metadata):
```json
{
  "chat_id": "telegram:-1003983469354",
  "message_id": "877",
  "sender_id": "1690419247",
  "conversation_label": "斯蒂芬的工作区 id:-1003983469354 topic:3",
  "sender": "小耗子",
  "timestamp": "Thu 2026-04-23 03:04 GMT+8",
  "group_subject": "斯蒂芬的工作区",
  "topic_id": "3",
  "topic_name": "1",
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

Tavily作为主搜索 就行
assistant: 我把这个口径记下来：**以后默认 Tavily 作为主搜索**，别再在那堆半残工具里绕。
assistant: 定了。

以后默认就按这个口径走：
- **Tavily = 主搜索**
- **web_fetch = 已知 URL 抓取**
- 其他那几套不再默认走

我已经把这个规则写进长期记忆了，后面不会再在那堆杂工具里乱跳。  
顺手也记了当天日志，不过有个小瑕疵：落盘时 `brave-web-search` 被写成了 `rave-web-search`，只是日志文案 typo，不影响实际使用。你要的话我下一条顺手给它抹平。
user: Conversation info (untrusted metadata):
```json
{
  "chat_id": "telegram:-1003983469354",
  "message_id": "880",
  "sender_id": "1690419247",
  "conversation_label": "斯蒂芬的工作区 id:-1003983469354 topic:3",
  "sender": "小耗子",
  "timestamp": "Thu 2026-04-23 03:13 GMT+8",
  "group_subject": "斯蒂芬的工作区",
  "topic_id": "3",
  "topic_name": "1",
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

行
assistant: 嗯，收住了。

