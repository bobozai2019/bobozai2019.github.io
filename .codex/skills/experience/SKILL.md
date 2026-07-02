---
name: experience
description: "Use when the user says /experience to record valuable insights, lessons learned, and experiences from the current conversation into the memory system."
---

# Experience Recording Skill

Record valuable experiences and lessons learned from conversations into the memory system.

## Trigger

User types `/experience` in the conversation.

## Workflow

You MUST follow these steps in order:

### Step 1: Review and Extract

Review the current conversation and identify valuable experiences. Look for:
- **Technical**: Bugs encountered, solutions found, debugging techniques, error patterns
- **Design**: Architecture decisions, design patterns used, technical choices and rationale
- **Workflow**: Tool usage patterns, process improvements, collaboration insights

Present all candidate experiences to the user as a numbered list. Each should have:
- A short title (5-10 words)
- A one-sentence summary of what was learned
- An inferred type with recommendation: `→ technical` / `→ design` / `→ workflow`

If no valuable experiences were found, tell the user honestly.

### Step 2: Confirm per experience

For each experience, use the `AskUserQuestion` tool to ask two things. **Always use options — never ask the user to type.**

**Question 1 — Scope**: Ask where to store this experience.
```
AskUserQuestion:
  questions:
    - question: "第 N 条「[标题]」存到哪里？"
      header: "存储位置"
      multiSelect: false
      options:
        - label: "项目"
          description: "存到项目级 .shared/knowledge/（仅当前项目可用）"
        - label: "全局"
          description: "存到全局 ~/.claude/memory/（所有项目可用）"
        - label: "跳过"
          description: "不记录这条经验"
```

**Question 2 — Type**: Ask which type, with the inferred type listed first.
```
AskUserQuestion:
  questions:
    - question: "第 N 条「[标题]」属于哪种类型？"
      header: "经验类型"
      multiSelect: false
      options:
        - label: "[推断类型]（推荐）"
          description: "根据内容自动推断"
        - label: "[其他类型1]"
          description: "..."
        - label: "[其他类型2]"
          description: "..."
```

The recommended option should always be the inferred type, listed first.

Inference rules:
- Bug 修复、报错处理、调试技巧、环境问题 → **technical**
- 架构决策、设计模式、技术选型、重构方案 → **design**
- 工具使用、流程优化、协作方式、效率提升 → **workflow**

### Step 3: Write Record

For each confirmed experience, append it to the appropriate file using this format:

```markdown
### [简短标题]

- **日期**: YYYY-MM-DD
- **标签**: #tag1 #tag2
- **上下文**: 什么场景下遇到的
- **经验**: 具体的经验内容
- **相关文件**: `path/to/file.ts`（可选）
```

### Step 4: Update Index

Update the MEMORY.md index file in the same directory. Each entry should be one line:

```markdown
- [标题](type.md) — 一句话摘要
```

## Storage Paths

### Project-level knowledge（Claude Code 和 Codex 共享）
```
.shared/knowledge/
├── MEMORY.md          # Index
├── technical.md       # Technical experiences
├── design.md          # Design experiences
└── workflow.md        # Workflow experiences
```

### Global memory
```
~/.claude/memory/
├── MEMORY.md          # Index
├── technical.md       # Technical experiences
├── design.md          # Design experiences
└── workflow.md        # Workflow experiences
```

## File Initialization

If a target file does not exist, create it with this header:

```markdown
# [Type] Experiences

> [项目级/全局]经验记录
```

If MEMORY.md does not exist, create it with:

```markdown
# Memory Index
```

## Important Notes

- Each experience should be self-contained and understandable without reading the full conversation
- Use concise, actionable language
- Include specific file paths, function names, or commands when relevant
- Tags should be lowercase, hyphenated (e.g., #websocket, #error-handling)
- Never duplicate existing experiences — check the file first
- **项目特定经验**（具体 bug、项目代码、业务逻辑）只能存项目级 `.shared/knowledge/`，不能存全局
- **通用经验**（框架特性、工具用法、设计模式）推荐存全局
- 如果用户选"全局"但内容是项目特定的，提醒并建议改为"项目"
