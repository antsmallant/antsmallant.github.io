---
layout: post
title: "ai 笔记：agent 协作"
date: 2026-04-26
last_modified_at: 2026-04-26
categories: [ai]
tags: [ai 工作 总结]
---

* 目录  
{:toc}
<br/>

# 1、记事

周四的时候，公司内部开了个 ai 交流会，同事分享和讨论了 ai 上的实践，遇到的问题，一些解法。我听下来，没有什么新东西，基本上还是偏单agent 使用上的一些技能，这些我基本上都实践了，全程我也几乎没发言，只在最后被Q到的时候，说了一下自己感兴趣以及正在研究的东西，其实就是现在说的 harness engineering 那套工程化的东西。

我比较关注工程化应用，2个方面：   
1、单个 agent 如何工程化的使用，最大化的减少人的介入，让 agent 从生产到验证到上线是闭环的。   
2、多个 agent 如何有效协作，完成过去需要一整个团队才能完成的项目。   

ai 的产能太高了，人类 review 和验证已经完全跟不上了，必须有机制，有工作流减少人的介入，把生产力真正提上去，同时确保产出质量符合预期。  


---

# 2、研究

## harness engineering 几个问题

1、是什么
2、为什么
3、然后呢

原始文章是哪个？
[Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/)
如果被跳转成中文版了，可以看这里：

英文版留存：[Harness engineering: leveraging Codex in an agent-first world](https://github.com/Rajat16nov/agentic-engineering/blob/main/resources/openai-harness-engineering.md)

中文版：[工程技术：在智能体优先的世界中利用 Codex](https://openai.com/zh-Hans-CN/index/harness-engineering/)


## harness engineering 相关文章

[Harness Engineering实践心得：如何高效驾驭AI？](https://mp.weixin.qq.com/s/NtsksL2gkMtMqkILi4xvRg)    


[Harness Engineering: 让 Coding Agent 可靠完成长程任务](https://xie.infoq.cn/article/cc898b22851f99970fec00494?utm_campaign=geek_search&utm_content=geek_search&utm_medium=geek_search&utm_source=geek_search&utm_term=geek_search)

[全行业都狂卷 Harness，Anthropic 还在加码，Codex 负责人却说它正在退场](https://www.infoq.cn/article/vblM3MlOEs86dmVdH8d1?utm_source=1&utm_medium=article)

[OpenAI 不想写 spec 了：Codex 只留 10 条要点，把执行交给 skills](https://www.infoq.cn/article/C2fWkH2EgBlDPNUNlcZX?utm_source=1&utm_medium=article)   

[motedb:Agent-First 软件工程](https://xie.infoq.cn/article/25241d69bf8e5578e037bc433?utm_campaign=geek_search&utm_content=geek_search&utm_medium=geek_search&utm_source=geek_search&utm_term=geek_search)
[motedb:一场变化真正开始深入现实，往往不是先改工具，而是先改语言。](https://xie.infoq.cn/article/80542a0c513645f25a03c3b3f) 
[motedb:Harness 的七层结构](https://xie.infoq.cn/article/d0d381dbd4a101884221f64f1)



## agent 使用上的技巧


## agent 能力的闭环


## 多 agent 协作
[智能体走向“企业操作系统”，Google 扔出五把钥匙](https://xie.infoq.cn/article/b1acfb77132dcb31fcad9b253?utm_campaign=geek_search&utm_content=geek_search&utm_medium=geek_search&utm_source=geek_search&utm_term=geek_search)


---

# 3、harness engineering 参考资料

## 分享定位

这次分享不建议讲成“某个新名词介绍”，而应讲成一个工程范式变化：

1. Prompt Engineering 解决“如何向模型表达意图”。
2. Context Engineering 解决“如何把任务所需上下文送到模型面前”。
3. Harness Engineering 解决“如何让 agent 在真实系统里可执行、可观测、可验证、可纠偏”。

重点观点：

- Coding Agent 的能力不只来自模型，也来自外部 harness。
- Agent 犯错时，不应只改 prompt；要问“缺了什么工具、约束、文档、测试或反馈信号”。
- 高质量 harness 的目标不是完全取消人工，而是把人工注意力移动到判断、取舍和目标设定上。
- 对团队而言，未来的工程效率瓶颈会越来越从“人手写代码”转向“人设计环境、反馈回路和控制系统”。

## 核心概念

### Harness 包含什么

面向 coding agent，可以把 harness 拆成这些层：

1. 指令层：system prompt、`AGENTS.md`、skills、团队规则、任务模板。
2. 上下文层：代码库结构、架构文档、产品规范、设计原则、历史决策、接口文档。
3. 工具层：shell、文件读写、Git、测试命令、lint、formatter、浏览器、截图、日志查询、数据库查询。
4. 执行层：sandbox、worktree、权限、网络访问、依赖安装、进程管理。
5. 验证层：单测、集成测试、E2E、类型检查、静态分析、结构测试、性能检查、LLM judge。
6. 观测层：trace、logs、metrics、screenshots、DOM snapshot、运行时事件、失败报告。
7. 反馈层：pre-completion checklist、review agent、CI、自动重试、错误归因、经验沉淀。
8. 记忆层：repo 内文档、progress file、feature list、执行计划、已知坑、agent 可读的知识库。

### Feedforward 和 Feedback

Martin Fowler 文章里最适合借用的框架是：

- Guides / feedforward controls：agent 行动前的引导，提前减少错误概率。例如 `AGENTS.md`、架构文档、编码规范、how-to、skills。
- Sensors / feedback controls：agent 行动后的传感器，让 agent 自我纠正。例如测试、lint、日志、截图、review agent、性能指标。

只做 feedforward，agent 不知道自己有没有做对。只做 feedback，agent 会反复踩同样的坑。Harness Engineering 要把两者连成闭环。

### Computational 和 Inferential

控制手段还可以分成两类：

- Computational：确定性、便宜、快。比如单测、lint、类型检查、结构分析、依赖规则、文件大小规则。
- Inferential：语义判断、慢、贵、不完全确定。比如 AI code review、LLM judge、架构评审 agent、产品体验评审 agent。

建议原则：

- 能用 deterministic tooling 抓住的，不要交给 LLM judge。
- LLM judge 用在语义判断、模糊需求、体验质量、架构取舍等确定性工具覆盖不到的地方。
- 快速、便宜、高置信度的检查尽量左移到 agent 本地循环里。
- 贵的、全局性的检查放到 CI、nightly 或专门的后台 agent。

## 关键材料索引

### 1. Mitchell Hashimoto: My AI Adoption Journey

链接：https://mitchellh.com/writing/my-ai-adoption-journey

适合放在“术语来源和个人实践”部分。

重点内容：

- 不要长期停留在 chatbot 模式，真正做工程任务需要 agent：能读文件、执行程序、发 HTTP 请求。
- 如果给 agent 验证自己工作的能力，它经常能修正自己的错误并防止回归。
- 他把 Harness Engineering 定义为：每当发现 agent 犯错，就工程化一个方案，让它以后不再犯同类错误。
- 两种主要形式：更新 `AGENTS.md` 这类隐式提示；编写真正的工具，例如截图、过滤测试、验证脚本。

可提炼成分享句：

```text
Harness Engineering 的起点不是“让模型更聪明”，而是“让错误变成下次不会再发生的工程资产”。
```

### 2. OpenAI: Harness engineering: leveraging Codex in an agent-first world

链接：https://openai.com/index/harness-engineering/

适合作为主案例。

关键事实：

- OpenAI 团队用 Codex 构建一个内部 beta 产品，约 5 个月，约百万行代码。
- 约 1,500 个 PR，由小团队驱动 Codex 完成。
- 原则是 “Humans steer. Agents execute.” 人负责目标、优先级、验收和判断；agent 负责执行。
- `AGENTS.md` 不应是千页手册，而应是目录。短入口文件指向 repo 内结构化知识库。
- UI、日志、metrics、traces 要让 Codex 直接可读，才能让它复现 bug、验证修复、优化性能。
- 架构约束要机械执行：custom linters、structural tests、边界校验、结构化日志、命名规则、文件大小限制。
- 技术债需要“垃圾回收”：后台 Codex task 周期性扫描偏离原则的代码，并提交小型重构 PR。

适合展示的工程变化：

```text
传统工程：人写代码，工具辅助。
Agent-first 工程：人设计环境、边界和反馈，agent 执行代码变更。
```

### 3. Martin Fowler: Harness engineering for coding agent users

链接：https://martinfowler.com/articles/harness-engineering.html

适合作为理论框架。

重点内容：

- Harness 是模型之外的一切，但在 coding agent 用户语境下，可以重点理解为“用户为 agent 额外构建的外层控制系统”。
- 一个好的 outer harness 有两个目标：提高 agent 首次做对的概率；在结果到达人类眼前之前尽量自我纠错。
- Feedforward guides 和 feedback sensors 是分析 harness 的基本框架。
- Computational 和 inferential 是两种控制类型。
- 三类 harness：
  - Maintainability harness：维护性、代码质量、重复代码、复杂度、测试覆盖、风格。
  - Architecture fitness harness：架构边界、性能要求、可观测性标准、依赖方向。
  - Behaviour harness：功能行为是否符合需求；目前仍然最难，因为不能只相信 agent 自己生成的测试。
- Harnessability：并不是所有代码库同样容易 harness。强类型、清晰模块边界、稳定框架、可测接口都会提高 agent 成功率。

### 4. Anthropic: Effective harnesses for long-running agents

链接：https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents

适合讲长任务和多上下文窗口。

重点内容：

- 长任务 agent 容易过早宣布完成、丢失上下文、留下脏环境、没有做端到端验证。
- Anthropic 的方案是 initializer agent + coding agent。
- initializer agent 负责写 `init.sh`、进度文件、feature list、初始 git commit。
- coding agent 每次只做一个 feature，开始时读进度和 git history，跑基础 E2E，结束时写进度和 commit。
- 用结构化 JSON feature list 比 Markdown 更不容易被模型随意改坏。

可落地到团队流程：

```text
每个长任务都需要：任务清单、进度文件、可重复启动脚本、基础 E2E、干净提交点。
```

### 5. Anthropic: Harness design for long-running application development

链接：https://www.anthropic.com/engineering/harness-design-long-running-apps

适合讲多 agent 架构。

重点内容：

- 采用 planner、generator、evaluator 三 agent 架构。
- planner 分解任务；generator 实现；evaluator 做评审和质量反馈。
- 生成器-评估器循环类似软件工程里的开发、评审和 QA。
- 结构化 artifacts 用于跨 session 传递上下文。

可以作为分享里的高级形态：

```text
当单个 coding agent 的自验证不够时，可以把“计划、实现、评估”拆成不同角色，并让 artifacts 成为交接面。
```

### 6. LangChain: The Anatomy of an Agent Harness

链接：https://www.langchain.com/blog/the-anatomy-of-an-agent-harness

适合讲“Agent Harness 到底有哪些零件”。

重点内容：

- Harness 由 system prompt、tools、skills、MCP、文件系统、sandbox、browser、orchestration、hooks/middleware 等组成。
- 文件系统是基础 primitive：agent 可以持久化状态、读写真实数据、跨 session 保存中间结果。
- Git 给文件系统加上版本、回滚、实验分支和协作能力。
- Bash/code execution 是通用工具，让 agent 不必为每个动作都预定义专门工具。
- Sandbox 让 agent 执行代码、安装依赖、验证结果时具备隔离性。
- Hooks/middleware 可以做 compaction、continuation、lint checks、self-verification 等。

### 7. LangChain: Improving Deep Agents with harness engineering

链接：https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering

适合讲数据案例。

关键事实：

- LangChain 在 Terminal Bench 2.0 上，保持模型固定为 `gpt-5.2-codex`，只优化 harness。
- deepagents-cli 分数从 `52.8` 提升到 `66.5`，提升 `13.7` 分。
- 他们优化的旋钮包括 system prompt、tools、middleware。
- 用 trace analysis 找失败模式：推理错误、不遵守任务要求、缺少测试验证、超时等。
- 增加 build-and-self-verify 流程：plan/discover、build、verify、fix。
- 使用 `PreCompletionChecklistMiddleware` 在 agent 退出前提醒做验证。
- 使用 `LocalContextMiddleware` 注入目录和工具上下文。
- 使用 `LoopDetectionMiddleware` 检测同一文件反复编辑，提醒 agent 跳出坏循环。
- 对 reasoning budget 做调度，规划和验证阶段多花推理，普通执行阶段控制成本。

这篇可以支撑一个强论点：

```text
Harness 不是包装概念。即使模型不变，只优化 harness，也能显著改变 agent 成果。
```

### 8. OpenAI Codex: AGENTS.md 官方文档

链接：https://developers.openai.com/codex/guides/agents-md

适合讲最小落地入口。

重点内容：

- Codex 会在工作前读取 `AGENTS.md`。
- 指令可以分层：全局 `~/.codex/AGENTS.md`，项目根目录 `AGENTS.md`，子目录 `AGENTS.override.md`。
- 可以通过 `project_doc_fallback_filenames` 让 Codex 识别团队已有的说明文件名。
- 这类文件适合放稳定规则、测试命令、项目约束、常见坑和工作约定。

建议实践：

```text
AGENTS.md 不要写成长篇百科。它应当是短入口、路线图和索引。
深层知识放到 docs/、howto/、architecture/、runbooks/，并保持可验证和可更新。
```

### 9. OpenAI API Web Search 文档

链接：https://developers.openai.com/api/docs/guides/tools-web-search

适合讲“如何让 agent 获得最新外部信息”。

重点内容：

- Responses API 通过 `tools: [{"type": "web_search"}]` 启用 web search。
- 默认响应会包含 inline citations。
- 可以通过 `filters.allowed_domains` 和 `filters.blocked_domains` 控制来源。
- 可以通过 `include=["web_search_call.action.sources"]` 获取完整 sources。
- 可以通过 `external_web_access: false` 让 web search 只使用缓存/索引结果。

### 10. OpenAI Codex Internet Access 文档

链接：https://developers.openai.com/codex/cloud/internet-access

适合讲安全配置。

重点内容：

- Codex cloud agent phase 默认关闭互联网访问。
- 开启互联网访问会增加 prompt injection、secret 外泄、恶意依赖、许可证等风险。
- 建议只开放必要域名和 HTTP methods，并审查 agent 输出和 work log。

## 推荐分享大纲

### 1. 开场：为什么不是 Prompt Engineering

要点：

- 过去我们把失败归因于 prompt 不够好。
- 但 coding agent 的失败常常来自环境缺能力：不知道项目规则、不能验证 UI、读不到日志、不能跑正确测试、缺少架构约束。
- 所以问题从“怎么问模型”变成“怎么设计 agent 的工程环境”。

可用例子：

```text
agent 老是跑错测试命令：这不是模型智商问题，是 repo 没有把正确命令放到 agent 一定会看到的位置。
agent 改完 UI 说成功但实际不可用：这不是一句 prompt 能解决的问题，需要浏览器、截图、DOM snapshot 和 E2E 验证。
agent 破坏架构边界：需要结构测试、lint 和可执行的架构规则。
```

### 2. 定义：Agent = Model + Harness

要点：

- 模型是核心能力，但不是完整系统。
- Harness 是模型外部的一切执行环境和控制系统。
- Harness Engineering 是把 agent 的成功条件工程化。

### 3. Harness 的零件

建议画成一层一层：

```text
Human intent
  -> Guides: AGENTS.md / docs / skills / specs
  -> Agent loop: plan / act / observe / revise
  -> Tools: shell / git / tests / browser / logs / search
  -> Sensors: test / lint / metrics / screenshots / review
  -> Feedback: fix / document / encode rule / add tool
```

### 4. 控制论框架：Guides + Sensors

要点：

- Guides 让 agent 第一次更可能做对。
- Sensors 让 agent 做错后能自己发现。
- 真正的 harness 是闭环，不是孤立文档或孤立测试。

### 5. 案例一：OpenAI 的 Codex-first 产品

讲法：

- 不是“Codex 写了很多代码”。
- 真正关键是团队把 repo、文档、架构、UI、日志、metrics、review、技术债管理都改造成 agent 可读、可执行、可验证。
- 人类从写代码移动到设计环境、任务、验收和反馈。

### 6. 案例二：Anthropic 的长任务 harness

讲法：

- 长任务不是靠一个超长 prompt。
- 需要 initializer agent 先搭好任务清单、启动脚本、进度文件和 git 基线。
- 后续 coding agent 每轮只做一个 feature，开始先恢复上下文和验证当前系统，结束留下干净状态。

### 7. 案例三：LangChain 的 benchmark 提升

讲法：

- 最能证明 harness 的价值：模型固定，只改 harness，Terminal Bench 2.0 分数从 52.8 到 66.5。
- 有效改动不是玄学，而是 trace 分析、环境上下文注入、退出前检查、自验证、坏循环检测、reasoning budget 调度。

### 8. 如何在团队落地

落地顺序：

1. 先建一个短 `AGENTS.md`。
2. 把测试、lint、启动、构建命令写清楚。
3. 把架构约束和目录职责写清楚。
4. 把常见失败沉淀成脚本、lint 或 checklist。
5. 让 agent 能读日志、跑测试、看截图、查 trace。
6. 把失败案例做成“下次自动防住”的规则。
7. 周期性清理 stale docs、技术债和坏模式。

## 团队落地 Checklist

### 最小版

- 项目根目录有短 `AGENTS.md`。
- `AGENTS.md` 包含构建、测试、lint、启动命令。
- `AGENTS.md` 指向更详细的 docs，而不是塞满所有内容。
- 有一条快速验证命令，agent 每次改动后能自己跑。
- 常见失败写进“已知坑”文档。
- agent 能读当前目录结构和关键文档。

### 进阶版

- 有稳定的 E2E 或 smoke test。
- 有结构化日志，错误信息能直接帮助 agent 修复。
- 有截图或浏览器自动化能力。
- 有架构边界检查，例如依赖方向、层级访问规则、文件大小限制。
- 有 custom lints，并且错误信息包含修复指引。
- 有 progress file 或 execution plan，适合长任务和多 session。
- 有 trace，能回看 agent 为什么失败。

### 高级版

- 多 worktree 或 sandbox，每个任务隔离运行。
- agent 可读 logs、metrics、traces。
- PR 前有 agent self-review 和 review agent。
- 使用 middleware/hook 做退出前验证、坏循环检测、上下文注入。
- 后台 agent 定期扫描技术债、stale docs、架构漂移。
- 针对不同任务有 harness template，例如 CRUD 服务、前端页面、数据管道、游戏 UI 流程。

## 可以直接引用的讲稿片段

### 片段一：定义

Harness Engineering 可以理解为给 AI Agent 修一条工程化轨道。模型本身会推理、会写代码，但它不知道我们的项目规则、无法天然看到运行结果，也不会自动拥有正确的验证方式。Harness 做的事，就是把上下文、工具、约束和反馈信号组织起来，让 agent 在做错时能被及时纠正，在反复犯错时能把错误沉淀成新的规则或工具。

### 片段二：为什么重要

Agent 的输出质量不是单纯由模型决定的。同一个模型，在一个没有文档、没有测试、没有日志、没有架构边界的仓库里，会表现得像盲人摸象；在一个可读、可测、可观测、可回滚的环境里，会表现得像能独立推进任务的工程成员。因此，提高 agent 成功率的关键，不只是换更强模型，而是改造它工作的环境。

### 片段三：人类角色变化

Harness Engineering 不是让人退出软件工程，而是让人的注意力上移。人不再把大部分时间花在敲代码和搬运上下文上，而是花在定义目标、拆分任务、设计约束、选择验证方式、判断取舍，以及把失败转化为下一次自动生效的工程资产上。

### 片段四：落地原则

每次 agent 犯错，不要只说“下次小心”。要问四个问题：它是不是缺少上下文？是不是缺少工具？是不是缺少验证信号？是不是缺少可执行约束？如果答案是肯定的，就把这次错误转化为 `AGENTS.md`、脚本、lint、测试、文档、hook 或 dashboard。Harness 就是在这些小改进中长出来的。

## 常见误区

### 误区一：Harness 就是写更长的 AGENTS.md

不是。长文档会占上下文、过时、互相矛盾，还难以验证。好的 `AGENTS.md` 应该短，像目录一样指向 deeper docs 和可执行工具。

### 误区二：LLM judge 可以替代测试

不能。确定性检查能覆盖的地方，应优先使用测试、lint、类型检查和结构分析。LLM judge 适合补足语义、体验、架构取舍等无法稳定编码的部分。

### 误区三：只要模型更强，就不需要 harness

模型变强会减少某些错误，但不会消除项目特定规则、运行时环境、业务知识、权限、安全和验证需求。越自治的 agent，越需要清晰的工具、边界和反馈。

### 误区四：Harness 一次建完

Harness 是持续演化的。每次失败、review comment、线上事故、重复手工检查，都是 harness backlog。

### 误区五：agent 自己生成测试并跑绿就够了

行为正确性仍然很难。agent 可能生成覆盖不足的测试，或者测试自己的实现而不是需求。关键业务逻辑需要人工定义验收标准、approved fixtures、E2E、mutation testing 或独立评估。

## 风险和安全

- Web search 和外部网页会带来 prompt injection 风险。
- Agent 拿到网络访问后，可能泄露代码、secret 或内部上下文。
- 依赖安装可能引入恶意包或许可证问题。
- 自动修复可能扩大改动范围，需要权限和审查边界。
- 长上下文文档可能过时，过时文档会误导 agent。
- 自动评审不能完全替代人类判断，尤其是产品目标、架构取舍、安全和合规。

建议：

- 网络访问默认最小化，使用 allowlist。
- Secret 不进入 agent 可读上下文。
- 高风险操作需要人工确认或 CI gate。
- 把 agent 可以执行的命令、目录和外部域名明确约束。
- 对 agent 的 work log、trace、PR diff 做抽样审查。

## 适合继续检索的关键词

英文：

- `harness engineering coding agents`
- `agent harness AI`
- `Agent = Model + Harness`
- `long-running agents harness`
- `coding agent feedback sensors`
- `AGENTS.md coding agents`
- `agent self verification middleware`
- `Terminal Bench harness engineering`
- `context engineering vs harness engineering`

中文：

- `Harness Engineering AI Agent`
- `AI Agent Harness 工程`
- `Coding Agent Harness`
- `Context Engineering Harness Engineering`
- `AGENTS.md 编码智能体`
- `AI 编程智能体 验证 闭环`

## 后续可扩展成 slides 的页标题

1. 从 Prompt Engineering 到 Harness Engineering
2. Agent = Model + Harness
3. Harness 不是一个工具，而是一套控制系统
4. Guides：让 agent 第一次更可能做对
5. Sensors：让 agent 做错后能自己发现
6. Computational vs Inferential
7. OpenAI 案例：Humans steer, agents execute
8. Anthropic 案例：长任务需要 artifacts 和 clean state
9. LangChain 案例：模型不变，只改 harness，分数提升
10. 团队落地：从一个短 AGENTS.md 开始
11. 失败如何沉淀成工程资产
12. 风险、安全和人的角色

## 参考链接

- Mitchell Hashimoto, My AI Adoption Journey: https://mitchellh.com/writing/my-ai-adoption-journey
- OpenAI, Harness engineering: leveraging Codex in an agent-first world: https://openai.com/index/harness-engineering/
- Martin Fowler, Harness engineering for coding agent users: https://martinfowler.com/articles/harness-engineering.html
- Anthropic, Effective harnesses for long-running agents: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Anthropic, Harness design for long-running application development: https://www.anthropic.com/engineering/harness-design-long-running-apps
- LangChain, The Anatomy of an Agent Harness: https://www.langchain.com/blog/the-anatomy-of-an-agent-harness
- LangChain, Improving Deep Agents with harness engineering: https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering
- OpenAI API, Web search: https://developers.openai.com/api/docs/guides/tools-web-search
- OpenAI Codex, Custom instructions with AGENTS.md: https://developers.openai.com/codex/guides/agents-md
- OpenAI Codex, Agent internet access: https://developers.openai.com/codex/cloud/internet-access
