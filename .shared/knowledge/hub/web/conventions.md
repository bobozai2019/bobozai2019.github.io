# Conventions Knowledge

## 2026-06-28: React setTimeout 闭包捕获 stale state — 用 useRef 解决 ⚠️

- **标签**: #react #closure #useRef #setTimeout #stale-state
- **症状**: setTimeout 回调中读取的 state 值永远是旧值，条件判断永远不成立
- **陷阱**: `useCallback` 依赖 `isRunning`，但 setTimeout 闭包在创建时捕获的是当时的值。如果 `handleRun` 在 `isRunning=false` 时调用，闭包内 `isRunning` 永远是 `false`，即使之后 `setIsRunning(true)` 更新了状态
- **根因**: JavaScript 闭包捕获的是变量的值（不是引用），`useCallback` 的依赖数组控制的是回调何时重建，但已创建的闭包不会更新
- **正确做法**: 用 `useRef` 跟踪需要在异步回调中读取的值：
  ```typescript
  const isRunningRef = useRef(false);

  const handleRun = useCallback(async () => {
    setIsRunning(true);
    isRunningRef.current = true;
    // ...
    setTimeout(() => {
      if (isRunningRef.current) { /* 这里能读到最新值 */ }
    }, 300000);
  }, [fetchLatest]); // 不需要依赖 isRunning
  ```
- **如何应用**: 任何在 setTimeout/setInterval/Promise 回调中需要读取"当前"状态值的场景，都用 useRef。useState 用于渲染，useRef 用于异步回调。

---

## 2026-05-27: 改动引擎适配器或 WS 代码的检查清单

改 engine-adapters.ts 前：
- 确认端口分配逻辑不会跳过已占用端口
- 确认进程退出后 runtime entry 被正确清理
- 确认 killProcessTree 能杀掉整个进程树

## 2026-06-06: iOS Safari iframe 中 COEP 需要 `allow="cross-origin-isolated"` ⚠️

- **标签**: #ios #safari #iframe #COEP #cross-origin
- **症状**: iOS Safari 上 iframe 加载带 COOP/COEP 头的页面时，`crossOriginIsolated` 为 `false`，SharedArrayBuffer 不可用，WASM 加载可能失败。桌面浏览器正常。
- **根因**: iOS Safari 对 iframe 的跨域隔离更严格。仅设置服务端 COEP 头不够，iframe 元素必须显式声明 `allow="cross-origin-isolated"` Permissions Policy。
- **修复**: `<iframe sandbox="..." allow="cross-origin-isolated"></iframe>`
- **如何应用**: 任何在 iframe 中加载需要 COEP 的内容（Godot WASM、SharedArrayBuffer 等）时，必须同时设置 iframe 的 `allow` 属性。

---

改 server.ts WS 处理前：
- 确认 reconnect 响应包含 isRunning 字段
- 确认 session-transferred 使用 message 字段（不是 data）
- 确认错误消息包含字段名（测试断言 includes('text')）

改 src/main.ts 前：
- 确认 WS onopen 中调用 requestSessionHistory
- 确认 onclose 中有重连逻辑
- 确认 reconnect 消息格式正确

## 2026-05-18: 快捷操作按钮按项目引擎类型动态渲染

不同引擎项目的构建/运行命令完全不同，不能用写死的按钮。

**How to apply:**
- 定义 `quickActions` 配置对象，按引擎类型分组，加 `_common` 公共操作
- 切换项目时调用 `renderQuickActions()` 重新渲染按钮并绑定事件
- 当前支持的引擎类型和对应操作：
  - `pure-web`（Vite 项目）：`npm run build` / `npm run dev -- --host 0.0.0.0`
  - `godot-web`（Godot 项目）：headless export 命令
  - 公共：`git status` / `git diff` / `git reset --hard HEAD`
- 新增引擎类型时只需在 `quickActions` 对象中加一组配置

## 2026-05-18: 远程代理网关架构原则 — 不自研 Agent

系统定位是"远程编程代理网关"，不是"自研 AI Agent 平台"。后端只做消息转发和终端桥接，真正的编程能力交给 Claude Code CLI。

**Why:** 自研 Agent（TS 直接调 Anthropic API → 自己实现文件读写/命令执行）会导致：重复造轮子、工程复杂度膨胀、偏离"让专业代理跟我交互"的原始需求。

**How to apply:**
- 后端职责：WebSocket 通信、spawn `claude -p`、流式转发 stdin/stdout、会话管理、预览链接
- 后端不负责：模型推理、Prompt 编排、工具调用、文件修改策略、代码生成
- 技术栈：Express + ws + child_process（或 node-pty），不引入 Anthropic SDK
- 安全：不保存 API Key（由 CLI 自己管理）、项目目录白名单、仅 Tailscale 内网访问
