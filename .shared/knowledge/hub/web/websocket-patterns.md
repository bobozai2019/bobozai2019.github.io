# WebSocket 代理和调试模式

### ws 库代理必须保留 isBinary 标志

- **日期**: 2026-05-26
- **标签**: #websocket #ws-library #binary #blob #proxy
- **上下文**: WebSocket 代理转发数据到浏览器
- **经验**: `ws` 库的 `message` 回调收到的 `data` 是 Buffer 类型，直接 `clientWs.send(data)` 会以二进制帧发送，浏览器收到 Blob 而非字符串，`JSON.parse(event.data)` 静默失败。正确做法：`upstream.on('message', (data, isBinary) => clientWs.send(data, { binary: isBinary }))`

### 同症状不同根因：WS 连接失败 vs 数据格式错误

- **日期**: 2026-05-26
- **标签**: #websocket #debugging #diagnosis
- **经验**: "数据不刷新"有两种根因：(1) WS 连接建立失败 — 表现为连接状态停在"连接中..."；(2) 连接成功但数据解析失败 — 表现为已连接但数据为空。排查先看连接状态，再验证数据类型（string vs Blob）

### Vite WS 代理对 iframe 内请求静默失效

- **日期**: 2026-05-27
- **标签**: #vite #websocket #proxy #iframe
- **经验**: Vite 的 `http-proxy` 配了 `ws: true` 的规则，对主页面 WS 正常转发，但对 iframe 中页面的 WS 请求静默丢弃（不报错、不转发）。修复：给加载 iframe 的代理规则也加 `ws: true`

### Vite 代理规则前缀匹配顺序影响 WS 转发

- **日期**: 2026-05-27
- **标签**: #vite #proxy #rule-order #websocket
- **经验**: Vite 代理按配置顺序匹配，路径前缀匹配优先级高于精确度。`/fullstack/xxx/ws/monitor` 会匹配 `/fullstack` 规则而非 `/ws/monitor` 规则。解决方案：给父规则加 `ws: true`，或使用不以父规则前缀开头的 WS 路径

### Express upgrade handler 直接处理 WS

- **日期**: 2026-05-27
- **标签**: #websocket #express #upgrade #proxy
- **经验**: Express 的 `server.on('upgrade')` 在 HTTP 层处理 WS 升级，不依赖 Vite 代理。当 Vite 代理层不可靠时，可在此直接路由 WS，配合 `WebSocketServer({ noServer: true })` + `handleUpgrade` 模式处理多路由

### WebSocket 代理协议必须匹配上游服务器 🔴

- **日期**: 2026-06-01
- **标签**: #websocket #proxy #wss #tls #iframe
- **陷阱**: 用 `ws://` 代理连接配置了 HTTPS 的上游 WebSocket 服务器
- **为什么容易犯**: `ws` 库默认用 `ws://`，容易忽略上游服务器是否启用了 TLS
- **后果**: 连接立即断开（协议不匹配），在 iframe 中触发 Vite HMR 全页刷新回退，形成无限刷新循环
- **正确做法**: 代理 HTTPS 上游时必须用 `wss://`，并加 `rejectUnauthorized: false` 信任自签名证书：`new WebSocket('wss://127.0.0.1:PORT/path', [], { rejectUnauthorized: false })`
- **如何发现**: 服务器日志反复出现 `upstream close: 1006` + `socket hang up`，iframe 页面资源被反复请求

### WS 多消息竞态：reconnect 的 clearFocus 覆盖 console-attach 焦点 🔴

- **日期**: 2026-06-06
- **标签**: #websocket #race-condition #focus #session-management
- **陷阱**: 服务器对 `reconnect` 消息在找不到会话时调用 `clearFocus(ws)`，会抹掉后续 `console-attach` 设置的焦点
- **为什么容易犯**: 前端同时发送 `console-attach` 和 `reconnect` 两个异步消息，假设它们按发送顺序处理。但 reconnect 的响应（含 clearFocus）可能在 console-attach 之后到达
- **后果**: Console 显示正常（输出流、状态 running），但每次键盘输入都被拒绝："当前连接没有输入焦点"
- **正确做法**: `handleReconnect` 在无会话时不应清除焦点——只在主动设置焦点到新会话时才覆盖旧焦点。`clearFocus` 仅用于明确的焦点转移场景
- **如何发现**: Console 输出正常但输入全部被拒；服务端日志显示 `console-attach` 成功后紧跟 `clearFocus`
