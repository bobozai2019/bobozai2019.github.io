# Web Technical Knowledge

### 前端资源清理的完整模式

- **日期**: 2026-05-22
- **标签**: #frontend #spa #cleanup #hmr #memory-leak
- **上下文**: Vite + TypeScript SPA 项目，有 setInterval、addEventListener、ECharts 图表实例、WebSocket 连接
- **经验**: SPA 中所有需要清理的资源（定时器、事件监听器、图表实例、WebSocket）必须在两处统一清理：(1) `window.addEventListener('beforeunload', ...)` 处理页面关闭/刷新；(2) `import.meta.hot.dispose(() => {...})` 处理 Vite HMR 热更新——HMR 时 `beforeunload` 不会触发，旧模块的定时器和监听器会残留，导致重复创建。事件回调需提取为变量（如 `const onResize = () => ...`）才能被 `removeEventListener` 移除

### xterm.js 后端进程退出后必须禁用 stdin

- **日期**: 2026-06-06
- **标签**: #xterm #terminal #stdin #ux #error-handling
- **症状**: 后端 PTY 进程退出后，用户继续在 xterm 终端中打字，每个按键都触发 "Console is not running" 错误消息刷屏
- **排查**: 前端 xterm 的 `onData` 回调始终活跃，每次输入都通过 WebSocket 发送 `console-input` 到服务器，服务器检查 `runtime.status !== 'running'` 后返回 error
- **根因**: xterm.js 默认不禁用 stdin 输入，需要显式设置 `term.options.disableStdin = true`
- **修复**: 监听后端状态变化（`console-status`、`console-exit`），在 status 不是 `running` 时调用 `setReadOnly(true)`；`console-attached` 时根据状态恢复
- **如何应用**: 任何将 xterm.js 作为远程终端使用的场景，都必须在后端进程不可写时禁用 stdin，否则会产生令人困惑的错误刷屏

### xterm.js 流式写入必须用 rAF 批处理

- **日期**: 2026-06-06
- **标签**: #xterm #terminal #rAF #batching #jitter #websocket
- **症状**: 远程终端输出含 `\r` 的进度行（如 `Working (6s • esc to interrupt)`）时，界面出现视觉抖动
- **根因**: WebSocket 逐 chunk 到达，每个 chunk 触发 xterm.js 独立的解析+渲染周期。PTY 每秒输出一个 `\r`-分隔的进度更新，导致每秒多次重绘
- **修复**: 在 `write()` 方法中用 `requestAnimationFrame` 缓冲，同一帧内的多个 chunk 合并为一次 `term.write()` 调用
- **如何应用**: 任何通过 WebSocket 向 xterm.js 流式写入数据的场景，都应使用 rAF 批处理，避免逐 chunk 渲染

### DOM 渲染终端输出必须处理 \r 和 ANSI 转义码

- **日期**: 2026-06-06
- **标签**: #terminal #ansi #carriage-return #dom #streaming
- **症状**: 将 raw 终端输出（如 codex CLI）直接用 `addLine()` 渲染到 DOM `<div>` 中，`\r` 被浏览器忽略（非回车），每个 chunk 创建新行，进度指示器刷屏
- **根因**: 终端 CLI 工具用 `\r`（回车符）原地刷新同一行（如进度条、spinner），但 DOM 的 `textContent` 不识别 `\r` 为行重写。同时 ANSI 转义码（`\x1b[31m` 等）在 DOM 中无意义
- **修复**: (1) 添加行缓冲：按 `\n` 分割完整行提交，`\r` 替换当前行内容而非新建元素；(2) `stripAnsi()` 剥离 ANSI 转义码；(3) 缓冲状态在 `terminal.innerHTML = ''` 时重置
- **如何应用**: 任何将 raw 终端输出渲染到 DOM（非 xterm.js）的场景，都需要 `\r`-as-rewrite 语义和 ANSI 剥离。如果可能，优先用 xterm.js 处理终端输出（它原生支持所有终端控制序列）
