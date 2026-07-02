---
name: bug-history
description: 从当前对话中提取 bug 和排查过程，按类型分类记录到项目的 .shared/knowledge/bug_history/ 目录。按类型分文件（vite-proxy.md、runtime.md、workflow.md 等），每类下可有多条记录。支持两种模式：(a) 显式指定 bug 内容记录；(b) 无参数时自动分析对话，提取所有遇到的问题。
---

# Bug History Recording Skill

从对话中提取 bug 排查经验，记录到项目的知识库。

## Trigger

User types `/bug-history` in the conversation.

## Workflow

### Step 1: Review and Extract

回顾当前对话，识别所有遇到的问题。每个 bug 应包含：

- **现象**：用户看到的错误表现
- **排查过程**：做了哪些测试、排除了哪些可能
- **根因**：问题的根本原因
- **修复**：如何解决的
- **经验教训**：如何提前发现、如何避免

如果没有找到 bug，如实告知用户。

### Step 2: Present Summary

以编号列表展示所有发现的 bug，每个包含：
- 简短标题（10 字以内）
- 一句话现象描述
- 严重程度标记：🔴 严重 / 🟡 中等 / 🟢 轻微

### Step 3: Confirm Recording

使用 `AskUserQuestion` 工具确认：

```
AskUserQuestion:
  questions:
    - question: "要记录哪些 bug？"
      header: "选择记录"
      multiSelect: true
      options:
        - label: "Bug 1: [标题]"
          description: "[一句话现象]"
        - label: "Bug 2: [标题]"
          description: "[一句话现象]"
        - label: "全部记录"
          description: "记录所有发现的 bug"
        - label: "跳过"
          description: "不记录"
```

### Step 4: Check Existing Files

检查项目的 `.shared/knowledge/bug_history/` 目录：
- 如果目录存在，读取同类型文件避免重复
- 如果目录不存在，创建它

### Step 5: Write Records

按类型分类，每个 bug 追加到对应类型文件末尾。常见类型：
- `vite-proxy.md` — Vite 代理、WS 转发、路径匹配相关
- `runtime.md` — 进程管理、端口冲突、服务健康相关
- `workflow.md` — git 操作、测试流程、协作方式相关
- 按需新增其他类型

每条记录格式：

```markdown
---

## YYYY-MM-DD: [简短标题] [严重程度标记]

**现象**: [错误表现]

**排查过程**:
1. [操作] — [结果]

**根因**: [精确描述]

**修复**: [方案]

```typescript
// 关键代码（可选）
```

**经验**: [可复用的教训]
```

## File Location

```
<project-root>/.shared/knowledge/bug_history/
├── vite-proxy.md    # Vite 代理相关
├── runtime.md       # 运行时问题
├── workflow.md      # 工作流问题
└── ...              # 按需新增类型
```

## Severity Markers

- 🔴 **严重**: 服务崩溃、数据丢失、功能完全不可用
- 🟡 **中等**: 功能部分不可用、有 workaround
- 🟢 **轻微**: 体验问题、性能问题、边缘情况

## Important Notes

- 排查过程要完整记录，包括走过的弯路和排除的假设
- 根因要精确到代码层面（文件名、函数名、配置项）
- 修复要可操作（附代码片段或配置变更）
- 经验教训要可复用（不依赖具体上下文）
- 同一问题的不同表现应合并为一条记录
- 已有记录不重复添加，但可以更新补充
- **Bug history 只存项目本地**（`.shared/knowledge/bug_history/`），不入 hub 知识库。如果某个 bug 揭示了通用模式（框架 bug、工具陷阱等），用 `/remember` 保存到 hub
