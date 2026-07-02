可以。我现在不能实时联网校验每个页面的最新结构，但下面这些基本都是稳定的一手文档、经典论文或主流工程框架入口。你可以按“先能做，再读深”的方式学。

## 0. 总路线：你要学的不是单个概念，而是一套 Agent Harness 能力

这组知识可以拆成 6 层：

| 层级 | 你要掌握什么 | 目标 |
|---|---|---|
| L1 LLM API | 调用模型、流式输出、结构化输出、函数调用、错误重试 | 会稳定接入模型 |
| L2 LLM 原理 | Transformer、Attention、Token、KV Cache、推理成本 | 知道为什么慢、贵、容易爆上下文 |
| L3 Prompt / Context | Prompt Engineering、Context Packing、RAG、Memory | 会组织输入，而不是只会写提示词 |
| L4 Agent Loop | Observe → Think/Plan → Act → Tool → Reflect | 会写基本 Agent Runtime |
| L5 Tool / MCP / Skills | Tool Use、MCP Server、Skills、权限、安全沙箱 | 会让 Agent 使用外部能力 |
| L6 Harness Engineering | Eval、Replay、Logging、Sandbox、Subagent、Multi-Agent | 会做可迭代、可调试、可评测的 Agent 系统 |

---

# 学习清单

## 1. LLM API 基础

你先要熟悉主流 API 的共同抽象：message、system prompt、streaming、tool call、structured output、token usage、rate limit、retry。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| OpenAI API | Chat/Responses、tools、structured output、streaming | [OpenAI Docs](https://platform.openai.com/docs) |
| OpenAI Cookbook | 示例工程、tool calling、RAG、evals | [OpenAI Cookbook](https://cookbook.openai.com/) |
| Anthropic API | Messages API、tool use、prompting、agent design | [Anthropic Docs](https://docs.anthropic.com/) |
| Gemini API | 多模态、长上下文、function calling | [Google AI for Developers](https://ai.google.dev/) |
| Hugging Face Inference | 开源模型调用、transformers、pipeline | [Hugging Face Docs](https://huggingface.co/docs) |

你要能做出的练习：

1. 写一个统一 LLM Client，支持 OpenAI / Anthropic / Gemini 任意一个。
2. 支持 streaming。
3. 支持 tool call。
4. 支持 JSON Schema 输出。
5. 支持 retry、timeout、日志记录、token 统计。

---

## 2. LLM 技术原理

这部分不用一开始就啃太深，但你至少要知道模型为什么这样工作。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| Transformer | self-attention、positional encoding、decoder-only 架构 | [The Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) |
| GPT 原理 | token prediction、causal LM、pretrain/fine-tune | [Andrej Karpathy: Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY) |
| Tokenizer | BPE、token 计数、中文/代码 token 成本 | [OpenAI Tokenizer](https://platform.openai.com/tokenizer) |
| Transformers 库 | 模型加载、generate、attention mask | [Hugging Face Transformers](https://huggingface.co/docs/transformers/index) |
| LLM 课程 | 从原理到训练/推理/应用 | [Hugging Face NLP Course](https://huggingface.co/learn/nlp-course/chapter1/1) |

你要重点理解这些概念：

- LLM 本质是 next token prediction。
- Prompt 不是“命令”，而是上下文条件。
- 上下文越长，推理越贵。
- 模型不会真的“记住”当前对话之外的东西，除非你把 memory 注入上下文。
- “Reasoning”很多时候是通过额外 token 进行搜索、分解、验证，而不是神秘能力。

---

## 3. KV Cache / 推理性能

Agent Harness 工程里，KV Cache 很重要，因为 Agent 往往多轮调用、多工具调用、长上下文。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| KV Cache 基础 | 为什么自回归生成可以缓存历史 token 的 K/V | [Hugging Face KV Cache 文档](https://huggingface.co/docs/transformers/cache_explanation) |
| vLLM | PagedAttention、连续批处理、高吞吐推理 | [vLLM Docs](https://docs.vllm.ai/) |
| PagedAttention | KV Cache 分页管理 | [vLLM Paper](https://arxiv.org/abs/2309.06180) |
| FlashAttention | attention 计算优化 | [FlashAttention Paper](https://arxiv.org/abs/2205.14135) |
| llama.cpp | 本地推理、量化、KV cache、上下文管理 | [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp) |

你要能回答这些问题：

- 为什么首 token 慢，后续 token 相对快？
- prefill 和 decode 有什么区别？
- KV Cache 占显存和上下文长度是什么关系？
- 为什么长上下文 Agent 成本高？
- 多轮 Agent 能不能复用 KV Cache？什么时候能，什么时候不能？
- prefix caching / prompt caching 的价值是什么？

---

## 4. Prompt Engineering

Prompt Engineering 是基础，但不要停留在“写漂亮提示词”。你要学的是如何把任务、约束、格式、工具、失败处理全部表达清楚。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| 基础提示词 | role、task、constraints、examples、output format | [Anthropic Prompt Engineering](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview) |
| OpenAI Prompting | 指令层级、结构化输出、工具调用 | [OpenAI Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering) |
| Few-shot | 示例如何影响输出分布 | [OpenAI Cookbook](https://cookbook.openai.com/) |
| Prompt Injection | 越权指令、恶意网页/文档内容 | [OWASP LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/) |

你要掌握的模板：

```text id="rihfno"
角色：你是什么
目标：你要完成什么
输入：用户给了什么
约束：不能做什么、必须遵守什么
流程：先分析什么，再输出什么
工具：什么时候用工具，什么时候不用
输出格式：JSON / Markdown / 表格 / diff
失败处理：信息不足、工具失败、冲突时怎么办
```

练习：

1. 把一个“模糊需求”改成可执行 prompt。
2. 把一个 prompt 改成 JSON schema 输出。
3. 给 prompt 加入防 prompt injection 规则。
4. 给工具调用加上“何时调用 / 何时不调用”的边界。

---

## 5. Context Engineering

这是 Agent 工程的核心。Prompt Engineering 是“怎么说”，Context Engineering 是“给模型看什么”。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| RAG | 检索、切块、embedding、rerank、引用 | [LlamaIndex Docs](https://docs.llamaindex.ai/) |
| LangChain RAG | 文档加载、retriever、vector store | [LangChain RAG Tutorials](https://python.langchain.com/docs/tutorials/rag/) |
| 向量数据库 | embedding、metadata filter、hybrid search | [Qdrant Docs](https://qdrant.tech/documentation/) / [Chroma Docs](https://docs.trychroma.com/) |
| Long Context | 上下文预算、recency bias、lost in the middle | [Lost in the Middle Paper](https://arxiv.org/abs/2307.03172) |
| Reranking | 检索后重排，提高上下文质量 | [Cohere Rerank Docs](https://docs.cohere.com/docs/reranking) |

你要理解：

- 不是上下文越多越好。
- 相关性、时效性、优先级、来源可信度都要排序。
- 对 Agent 来说，context 通常包括：用户目标、历史对话、工具结果、文件片段、长期记忆、当前计划、失败记录。
- Memory 不等于 RAG。Memory 是“用户/任务状态”，RAG 是“外部知识检索”。
- 上下文需要压缩、摘要、引用、去重、排序。

建议你做一个 Context Packer：

```text id="8np28n"
输入：
- user request
- conversation history
- retrieved docs
- memory
- tool results
- system constraints

输出：
- final prompt context
- token budget report
- dropped items
- citations
```

---

## 6. Agent Loop

Agent Loop 是 Agent 的执行心脏。

基本结构：

```text id="8ke2vj"
while not done:
    observe current state
    decide next step
    call LLM
    maybe call tool
    read tool result
    update state
    check stop condition
```

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| ReAct | Reason + Act，边思考边调用工具 | [ReAct Paper](https://arxiv.org/abs/2210.03629) |
| Toolformer | 模型学习使用工具的早期思路 | [Toolformer Paper](https://arxiv.org/abs/2302.04761) |
| LangGraph | 状态机式 Agent 编排 | [LangGraph Docs](https://langchain-ai.github.io/langgraph/) |
| LlamaIndex Agents | 工具调用、检索、workflow | [LlamaIndex Agents](https://docs.llamaindex.ai/) |
| AutoGen | Multi-agent conversation framework | [Microsoft AutoGen](https://microsoft.github.io/autogen/) |
| CrewAI | 多 Agent 角色协作 | [CrewAI Docs](https://docs.crewai.com/) |

你要能实现 3 种 Agent：

### A. Tool Agent

能根据用户需求选择工具，例如搜索、读文件、写文件、查数据库。

### B. Planner Agent

先拆任务，再逐步执行。

```text id="zi077n"
user goal
→ plan
→ step 1
→ tool
→ result
→ step 2
→ final answer
```

### C. Reflection Agent

执行后自检：

```text id="8ukq6q"
answer
→ check against requirements
→ find missing parts
→ revise
```

---

## 7. Tool Use / Function Calling

Tool Use 是 Agent 真正能“做事”的关键。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| OpenAI Function Calling | JSON schema、tool choice、parallel tools | [OpenAI Function Calling Docs](https://platform.openai.com/docs/guides/function-calling) |
| Anthropic Tool Use | 工具定义、工具结果回填 | [Anthropic Tool Use Docs](https://docs.anthropic.com/) |
| JSON Schema | 参数约束、类型校验 | [JSON Schema Docs](https://json-schema.org/learn/getting-started-step-by-step) |
| 防注入 | 工具权限、参数校验、human approval | [OWASP LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/) |

你要重点练：

1. 给工具写 schema。
2. 让模型选择工具。
3. 工具结果回填给模型。
4. 工具失败时 retry。
5. 危险操作加人工确认。
6. 日志里保存每一次 tool call。

一个好的工具定义要包括：

```text id="yi836j"
工具做什么
什么时候用
什么时候不用
参数 schema
返回结构
失败类型
权限风险
是否需要用户确认
```

---

## 8. Reasoning / Planning

Reasoning 和 Planning 容易被神化。工程上你要关注的是：如何让模型稳定拆解任务、验证中间结果、减少乱做。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| Chain-of-Thought | 分步推理的基础思想 | [CoT Paper](https://arxiv.org/abs/2201.11903) |
| Self-Consistency | 多路径采样后投票 | [Self-Consistency Paper](https://arxiv.org/abs/2203.11171) |
| Tree of Thoughts | 搜索式推理 | [Tree of Thoughts Paper](https://arxiv.org/abs/2305.10601) |
| Reflexion | 失败后反思和改进 | [Reflexion Paper](https://arxiv.org/abs/2303.11366) |
| ReAct | 推理 + 行动循环 | [ReAct Paper](https://arxiv.org/abs/2210.03629) |

工程上要学会区分：

| 能力 | 工程实现 |
|---|---|
| Reasoning | 让模型产生中间分析、检查约束、比较方案 |
| Planning | 生成任务步骤、依赖关系、停止条件 |
| Reflection | 对结果做自检和修正 |
| Verification | 用工具、测试、规则、schema 验证 |
| Search | 多方案探索，不满意就回退 |

不要只依赖“让模型想清楚”。更可靠的是：

```text id="bvi47d"
LLM plan
+ tool execution
+ deterministic checks
+ eval tests
+ replay logs
```

---

## 9. Skills

Skills 可以理解为“可复用能力包”。它通常包含说明、脚本、模板、工具调用规则、示例、约束。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| Skill 概念 | 把复杂任务封装成可复用能力 | [Anthropic Docs](https://docs.anthropic.com/) |
| OpenAI Apps / Tools | 工具和应用能力暴露 | [OpenAI Apps SDK](https://developers.openai.com/apps-sdk/) |
| LangChain Tools | 自定义工具和工具包 | [LangChain Tools](https://python.langchain.com/docs/concepts/tools/) |
| LlamaIndex Tools | Query engine tool、function tool | [LlamaIndex Tools](https://docs.llamaindex.ai/) |

你可以把 Skill 设计成这样：

```text id="2dw3kr"
skill/
  SKILL.md          # 说明这个 skill 什么时候用
  examples/         # 示例输入输出
  scripts/          # 可执行脚本
  templates/        # 输出模板
  tests/            # 验证用例
```

练习项目：

- 做一个“生成 Steam 游戏市场分析报告”的 Skill。
- 做一个“Godot 项目结构分析”的 Skill。
- 做一个“从需求生成 OpenSpec 文档”的 Skill。
- 做一个“抓取独立游戏资讯并分类”的 Skill。

这个方向和你之前做的 Steam 后台、Godot 项目分析、Agent Harness 都很贴。

---

## 10. MCP：Model Context Protocol

MCP 是现在 Agent 工程里很重要的接口标准。可以把它理解成：让模型/Agent 通过统一协议连接外部工具、文件、数据库、浏览器、GitHub、IDE 等。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| MCP 官方文档 | server、client、tools、resources、prompts | [MCP Docs](https://modelcontextprotocol.io/) |
| MCP GitHub | SDK、示例 server | [Model Context Protocol GitHub](https://github.com/modelcontextprotocol) |
| TypeScript SDK | 写 MCP Server | [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk) |
| Python SDK | Python MCP Server | [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk) |

你要掌握：

- MCP Server 暴露工具。
- MCP Client 连接工具。
- Tool / Resource / Prompt 的区别。
- 如何给本地文件系统、数据库、GitHub、浏览器做 MCP Server。
- 如何限制权限，避免 Agent 乱读乱写。

练习：

1. 写一个本地文件读取 MCP Server。
2. 写一个 Steam 数据查询 MCP Server。
3. 写一个 Godot 项目扫描 MCP Server。
4. 接入 Claude Desktop / Cursor / Codex 类工具测试。

---

## 11. Memory

Memory 是 Agent 长期可用的关键，但也是最容易做烂的模块。

| 类型 | 说明 |
|---|---|
| Short-term Memory | 当前对话上下文 |
| Working Memory | 当前任务状态、计划、工具结果 |
| Long-term Memory | 用户偏好、项目状态、长期事实 |
| Episodic Memory | 历史任务记录 |
| Semantic Memory | 文档、知识库、概念 |
| Procedural Memory | 技能、流程、操作习惯 |

推荐资料：

- [MemGPT Paper](https://arxiv.org/abs/2310.08560)
- [LangGraph Memory](https://langchain-ai.github.io/langgraph/concepts/memory/)
- [LlamaIndex Memory](https://docs.llamaindex.ai/)
- [Zep Memory](https://help.getzep.com/)

你要学会设计 memory 写入规则：

```text id="6ye27y"
什么时候写？
写什么？
谁审核？
过期时间？
是否敏感？
如何召回？
如何删除？
如何避免错误记忆污染？
```

不要什么都记。好的 Memory 系统应该有：

- relevance score
- confidence score
- timestamp
- source
- expiry
- user editable
- delete mechanism

---

## 12. Subagent / Multi-Agent

多 Agent 不是“角色越多越强”。很多时候多 Agent 会增加成本、延迟和混乱。你要理解什么时候需要拆。

| 主题 | 必学点 | 推荐资料 |
|---|---|---|
| AutoGen | 多 Agent 对话、工具协作 | [Microsoft AutoGen](https://microsoft.github.io/autogen/) |
| CrewAI | 角色型 Agent 协作 | [CrewAI Docs](https://docs.crewai.com/) |
| LangGraph | 状态图、多节点 Agent | [LangGraph Docs](https://langchain-ai.github.io/langgraph/) |
| CAMEL | 多 Agent 研究框架 | [CAMEL AI](https://www.camel-ai.org/) |

什么时候需要 Subagent？

| 场景 | 是否适合 |
|---|---|
| 一个任务有明显子领域 | 适合 |
| 需要并行搜索/并行分析 | 适合 |
| 需要 critic/reviewer | 适合 |
| 只是想让回答更聪明 | 不一定 |
| 任务本来很简单 | 不适合 |

经典结构：

```text id="5tcetp"
Manager Agent
  ├── Research Agent
  ├── Coding Agent
  ├── Reviewer Agent
  └── Tool Agent
```

练习：

做一个“游戏行业简报 Multi-Agent”：

- Search Agent：收集新闻
- Analyst Agent：判断价值
- Product Agent：提炼对你项目的启发
- Editor Agent：输出日报

---

## 13. Harness Engineering

这是你最应该重点学的部分。Harness 不是单纯 Agent，也不是 Prompt，而是整个“模型执行环境”。

一个 Agent Harness 通常包括：

```text id="83tl4b"
LLM Client
Tool Registry
Context Manager
Memory Manager
Planner
Executor
Sandbox
Logger
Evaluator
Replay System
Permission System
Human Approval
Error Recovery
Observability Dashboard
```

| 模块 | 你要掌握什么 |
|---|---|
| LLM Client | 多模型接入、retry、fallback、stream |
| Tool Registry | 工具注册、schema、权限、版本 |
| Context Manager | 上下文拼装、压缩、引用、预算 |
| Planner | 任务拆解、DAG、依赖 |
| Executor | 步骤执行、工具调用、状态更新 |
| Sandbox | 文件/命令/网络隔离 |
| Memory | 写入、召回、纠错、删除 |
| Eval | 成功率、成本、延迟、错误类型 |
| Replay | 复现 Agent 的每一步 |
| Observability | trace、token、tool call、失败原因 |

推荐资料：

- [LangSmith](https://docs.smith.langchain.com/)
- [OpenAI Evals](https://github.com/openai/evals)
- [Promptfoo](https://www.promptfoo.dev/)
- [Ragas](https://docs.ragas.io/)
- [Phoenix by Arize](https://docs.arize.com/phoenix)
- [Langfuse](https://langfuse.com/docs)

你要做的核心项目：

> 自己实现一个 Mini Agent Harness。

功能要求：

1. 支持多模型配置。
2. 支持 tool registry。
3. 支持 agent loop。
4. 支持 plan / execute / reflect。
5. 支持 memory。
6. 支持 MCP tool。
7. 支持日志 replay。
8. 支持 eval case。
9. 支持 human approval。
10. 支持任务失败恢复。

---

# 推荐学习顺序

## 第 1 阶段：LLM API + Tool Calling

目标：能稳定调用模型和工具。

学习：

- OpenAI Docs
- Anthropic Docs
- OpenAI Cookbook
- JSON Schema
- Function Calling

产出：

- 一个 CLI Chatbot
- 一个支持 tool call 的 Agent
- 一个天气/文件/数据库查询工具

---

## 第 2 阶段：LLM 原理 + KV Cache

目标：知道 Agent 成本和性能瓶颈在哪里。

学习：

- The Illustrated Transformer
- Karpathy GPT 视频
- Hugging Face Transformers
- vLLM
- KV Cache

产出：

- tokenizer 计数器
- prompt cost calculator
- 简单本地模型推理 demo
- 对 prefill/decode/KV cache 写一篇笔记

---

## 第 3 阶段：Prompt + Context Engineering

目标：会给模型组织高质量上下文。

学习：

- Prompt Engineering
- RAG
- embedding
- reranking
- long context
- memory

产出：

- 文档问答 RAG
- context packer
- memory manager
- prompt injection 防护 demo

---

## 第 4 阶段：Agent Loop + Planning

目标：能做会分步骤执行的 Agent。

学习：

- ReAct
- Tree of Thoughts
- Reflexion
- LangGraph
- LlamaIndex Agents

产出：

- ReAct Agent
- Planner/Executor Agent
- Reflection Agent
- 带失败重试的 Tool Agent

---

## 第 5 阶段：MCP + Skills

目标：能把外部能力标准化接入 Agent。

学习：

- MCP Docs
- MCP TS/Python SDK
- Skills 设计
- Tool Registry

产出：

- 文件系统 MCP Server
- Steam 数据 MCP Server
- Godot 项目分析 Skill
- OpenSpec 文档生成 Skill

---

## 第 6 阶段：Harness Engineering

目标：做一个真正可调试、可评测、可迭代的 Agent Runtime。

学习：

- LangSmith
- Langfuse
- Promptfoo
- OpenAI Evals
- Ragas
- Phoenix

产出：

- Mini Agent Harness
- trace dashboard
- eval dataset
- replay system
- permission system
- multi-agent workflow

---

# 最小必读资料清单

下面这些优先级最高：

1. [OpenAI Docs](https://platform.openai.com/docs)  
2. [OpenAI Cookbook](https://cookbook.openai.com/)  
3. [Anthropic Docs](https://docs.anthropic.com/)  
4. [Hugging Face NLP Course](https://huggingface.co/learn/nlp-course/chapter1/1)  
5. [The Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/)  
6. [Andrej Karpathy: Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY)  
7. [Hugging Face Transformers](https://huggingface.co/docs/transformers/index)  
8. [vLLM Docs](https://docs.vllm.ai/)  
9. [ReAct Paper](https://arxiv.org/abs/2210.03629)  
10. [LangGraph Docs](https://langchain-ai.github.io/langgraph/)  
11. [LlamaIndex Docs](https://docs.llamaindex.ai/)  
12. [MCP Docs](https://modelcontextprotocol.io/)  
13. [OWASP LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/)  
14. [Promptfoo](https://www.promptfoo.dev/)  
15. [Langfuse Docs](https://langfuse.com/docs)  

---

# 我建议你做的 5 个实战项目

## 项目 1：LLM API Playground

功能：

- 多模型切换
- streaming
- JSON 输出
- token 统计
- cost 统计
- prompt 模板管理

对应知识：

- LLM API
- Prompt Engineering
- Structured Output

---

## 项目 2：Tool Calling Agent

功能：

- 工具注册
- schema 校验
- 工具调用
- 工具失败 retry
- 危险操作确认

对应知识：

- Tool Use
- Agent Loop
- Harness Engineering

---

## 项目 3：Context Manager / RAG 系统

功能：

- 文档切块
- embedding
- 向量搜索
- rerank
- 引用来源
- token budget 控制

对应知识：

- Context Engineering
- RAG
- Memory

---

## 项目 4：MCP Server

功能：

- 暴露本地文件读取工具
- 暴露 Steam 游戏数据查询工具
- 暴露 Godot 项目扫描工具
- 接入 Claude/Cursor/Codex 类客户端

对应知识：

- MCP
- Tools
- Skills
- Harness

---

## 项目 5：Mini Agent Harness

功能：

- Agent Loop
- Planner
- Executor
- Tool Registry
- Memory
- Eval
- Replay
- Logging
- Human Approval
- Multi-Agent

这是最接近 Agent Harness 岗位要求的项目。

---

# 最终学习目标

学完后你应该能讲清楚并实现这套链路：

```text id="5t2nth"
User Goal
→ Context Engineering
→ Prompt / System Instruction
→ LLM Reasoning
→ Planning
→ Tool Selection
→ Tool Execution
→ Observation
→ Memory Update
→ Reflection
→ Final Answer
→ Eval / Replay / Debug
```

也就是：你不是只会“调 API”，而是能设计一个可控、可调试、可扩展的 Agent 执行系统。
