---
name: recall
description: "搜索知识库中的相关洞察。搜索范围：hub 知识库 + 项目本地 .shared/knowledge/ + 全局 ~/.claude/memory/。"
---

# Recall — Knowledge Search

搜索知识库中的知识。搜索范围包括三个位置。

## Trigger

用户调用 `/recall`，或说"查一下知识库"、"有没有相关经验"等。

## 搜索范围

```
D:/AIprogram/myaitool/knowledge/     — Hub 知识库（通用/跨项目）
.shared/knowledge/                    — 项目本地知识（Claude Code + Codex 共享）
~/.claude/memory/                     — 全局 memory（用户级）
```

## Process

### 无参数 — 列出概览

读取三个知识目录下所有知识文件，统计条目数（`## ` 标题）：

```
知识库概览：

| 位置 | 目录 | 文件 | 条目数 |
|------|------|------|--------|
| hub | nodejs | technical.md | 5 |
| hub | godot | engine-quirks.md | 4 |
| hub | web | issues.md | 7 |
| 项目 | .shared/knowledge | technical.md | 3 |
| 全局 | ~/.claude/memory | technical.md | 2 |
| ... | ... | ... | ... |
```

### 关键词搜索

用 `Grep` 搜索三个目录下所有 `.md` 文件：

1. 搜索 `$ARGUMENTS` 关键词（不区分大小写）
2. 返回匹配条目，包含来源（hub/项目/全局）、分类、日期和内容
3. 无匹配时建议相关分类

### 分类浏览

如果 `$ARGUMENTS` 匹配分类关键词：

1. 先读取 `D:/AIprogram/myaitool/knowledge/INDEX.md`
2. 在索引中匹配分类名、文件名或说明（如 `godot`、`web`、`nodejs`、`git`、`vite`、`websocket`）
3. 按索引里的相对路径读取对应文件或目录并列出条目

特殊范围关键词：

- `项目` / `local` — `.shared/knowledge/*.md`
- `全局` / `global` — `~/.claude/memory/*.md`

### 特殊查询

- `problems` / `issues` / `fixes` — 搜索所有包含 `**症状:**` 或 `**根因:**` 或 `**修复:**` 的条目，作为问题-解决索引
- `recent` / `latest` — 最近 7 天的条目，按日期分组
- `anti-pattern` / `陷阱` — 搜索反模式条目

### 输出格式

```
找到 N 条相关知识：

1. [hub | nodejs | 日期] 标题
   经验: ...

2. [项目 | .shared/knowledge | 日期] 标题
   经验: ...

3. [全局 | ~/.claude/memory | 日期] 标题
   经验: ...
```

## 知识路径

Hub 知识路径以 `D:/AIprogram/myaitool/knowledge/INDEX.md` 为准。不要在技能内维护第二份目录树；如果知识文件移动或新增，只更新 `knowledge/INDEX.md`。

.shared/knowledge/
├── MEMORY.md    — Index
├── technical.md — 项目特定技术经验
├── design.md    — 项目特定设计经验
└── workflow.md  — 项目特定工作流经验

~/.claude/memory/
├── MEMORY.md
├── technical.md
├── design.md
└── workflow.md
```
