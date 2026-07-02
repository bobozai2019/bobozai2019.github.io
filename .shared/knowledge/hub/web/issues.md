# Web Issues

## 2026-05-27: iframe 嵌入项目用绝对路径导致 API 404 ⚠️

**The trap:** 被嵌入 iframe 的前端项目用 `fetch("/api/config")` 绝对路径调用自身后端。独立运行时正常，但被控制面板嵌入后，浏览器 origin 变成 `https://control-panel:3001`，绝对路径解析到控制面板而非 Vite dev server。

**Why it's tempting:** `fetch("/api/xxx")` 是最常见的写法，独立开发时完全正常，不容易意识到 iframe 嵌入会改变 URL 解析行为。

**What breaks:** 所有 API 调用（config、uploads、probe、jobs、SSE events）全部 404，因为请求打到了 control-panel Express 而非 Vite proxy。

**Failed paths:**
- 在 server.ts 加反向代理拦截 `/fullstack/:projectId/api/*` → 引入 SSE 流式转发、query string 丢失、header 过滤等新问题，复杂度爆炸
- 靠 Vite proxy 修复 → Vite proxy 只在 Vite 是浏览器 origin 时生效，iframe 场景下请求根本不会经过 Vite

**The right way:** 改源码用相对路径 `fetch("api/config")`（去开头 `/`）。浏览器基于当前页面路径解析：独立 dev 时页面在 `/` 解析为 `/api/config`；嵌入时页面在 `/fullstack/mp4-to-frames/` 解析为 `/fullstack/mp4-to-frames/api/config`，Vite proxy 自动处理。

**How to spot it early:**
- 项目要被 iframe 嵌入时，检查所有 `fetch("/...")` 和 `new EventSource("/...")` 调用
- grep `fetch("/` 和 `EventSource(/` 快速定位绝对路径
- 同时改 vite.config 加 `base` 匹配代理路由前缀

---

## 2026-05-27: node-fullstack 项目 Vite 配置标准模式

**Content:** node-fullstack 类型项目的 Vite dev server 必须配置 `base` 和 `https`，否则通过控制面板代理访问时 502 或资源 404。参考 `web-game-demo/vite.config.ts` 的模式：`base: '/fullstack/{projectId}/'`，`https` 指向 `control-panel/certs/` 的自签名证书。

**Why:** control-panel 的 fullstack proxy 用 `https://` 转发请求到 Vite，Vite 必须有 HTTPS 才能接收。`base` 必须匹配代理路由前缀，否则 HTML 中的 asset 路径会 404。

**How to apply:** 新增 node-fullstack 项目时，复制 `web-game-demo/vite.config.ts` 作为模板，只改 `base` 中的项目 ID 和 `proxy` 中的后端地址。`certDir` 路径指向 `control-panel/certs/`。

---

## 2026-05-27: 用反向代理修复源码问题导致复杂度爆炸 ⚠️

**The trap:** 发现 iframe 嵌入后 API 404，第一反应是在 server.ts 加一层反向代理来"修复"路由问题，而不是改源码用相对路径。

**Why it's tempting:** 不想改"别人的代码"（MP4toFrame），觉得在控制面板加代理更"解耦"。

**What breaks:** 反向代理需要处理 SSE 流式转发（不能 buffer）、query string 保留（SSE token 认证）、hop-by-hop header 过滤、try-catch 错误处理。引入 2 个 CRITICAL + 2 个 HIGH 级别的新问题。

**The right way:** 源码层面的问题在源码层面解决。改 7 行 `fetch` 路径比加 50 行代理代码更简单、更可靠。改动范围是信号——"加一个项目"不应该需要改 server.ts 核心路由。

**How to spot it early:**
- 如果修复一个问题需要引入比原问题更多的新问题，方案大概率选错了
- "不改别人代码"不适用于同仓库项目
- 改动 server.ts 前先问：能不能在源码层面解决？

---

## 2026-05-27: E2E 测试访问 iframe 内容用 frameLocator

**Content:** Playwright 测试访问 sandbox iframe 内容时，用 `page.frameLocator('#iframeId')` 而非 `page.evaluate(() => document.querySelector('iframe').contentDocument)`。后者通过主页面上下文跨域访问 iframe DOM，在 Chromium GC 压力下约 50% 概率返回空白。

**Why:** `frameLocator` 通过 CDP（Chrome DevTools Protocol）直接在 iframe 内部执行上下文操作，不受 GC 回收影响。`contentDocument` 是跨上下文引用，会被 Chromium 的垃圾回收器在内存压力下回收。

**How to apply:**
```ts
// 错误 — flaky
const content = await page.evaluate(() => document.querySelector('iframe').contentDocument?.body?.innerText)

// 正确 — stable
const frame = page.frameLocator('#iframeId')
await expect(frame.getByRole('heading', { name: /xxx/ })).toBeVisible()
```

---

## 2026-05-25: WebSocket 路径冲突导致数据格式不匹配 ⚠️

**The trap:** web-game-demo 通过 `/ws` 获取系统监控数据，控制面板的 `/ws` 也代理到 Claude Code 后端（3001）。两个 WebSocket 端点共用同一路径，导致前端收到的是 Claude Code 的流式 JSON 而非系统监控数据。

**Why it's tempting:** WebSocket 路径看起来是独立的，但实际上共享同一 HTTP server 时，`ws` 库的 `WebSocketServer` 的 `path` 选项会互相干扰。

**What breaks:** 前端连接 `/ws` 后收到的消息格式完全不对，图表无法解析数据，显示为空。

**Failed paths:**
- 尝试用两个 `WebSocketServer` 实例分别设置 `path: '/ws'` 和 `path: '/ws/monitor'` → 在共享 HTTP server 上导致 400 错误
- 尝试在 Vite proxy 中配置多个 WS 路径 → 前缀匹配顺序问题

**The right way:** 使用 `noServer: true` 模式创建单个 `WebSocketServer`，手动监听 `server.on('upgrade')` 事件，根据请求路径路由到不同的后端服务。

**How to spot it early:**
- 同一 HTTP server 上有多个 WebSocket 端点时
- 前端收到的消息格式与预期不符
- `ws` 库报 400 错误通常是路径冲突

## 2026-05-25: Vite proxy 代理 HTTPS 后端协议不匹配

**Symptom:** Vite proxy 配置 `target: 'http://localhost:3001'`，但后端使用自签名 HTTPS 证书，导致 502 Bad Gateway。

**Investigation:**
- 检查后端日志确认 HTTPS 正常运行
- 检查 Vite proxy 配置发现使用 `http://`
- 尝试添加 `secure: false` 无效（因为是协议不匹配而非证书问题）

**Root cause:** Vite proxy 使用 HTTP 协议连接 HTTPS 后端，协议不匹配导致连接失败。

**Fix:** 将 proxy target 改为 `https://localhost:3001`，并设置 `secure: false` 以容忍自签名证书。同时需要设置 `process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'`。

**How to apply:**
- 当后端使用 HTTPS 时，proxy target 必须用 `https://`
- 自签名证书需要 `secure: false` + `NODE_TLS_REJECT_UNAUTHORIZED=0`
- 在后端入口文件顶部设置环境变量

## 2026-05-25: Vite base 路径配置缺失导致代理下资源 404

**Symptom:** 通过控制面板代理访问全栈项目时，HTML 加载成功但 JS/CSS 资源 404。

**Investigation:**
- 检查 HTML 源码发现资源路径为绝对路径 `/src/main.ts`
- 通过代理访问时路径解析错误

**Root cause:** Vite 默认使用绝对路径 `/` 作为 base，代理环境下需要使用项目特定的 base 路径。

**Fix:** 在 `vite.config.ts` 中设置 `base: '/fullstack/project-id/'`，使资源路径变为相对于项目子路径。

**How to apply:**
- 全栈项目通过代理访问时，必须配置 `base` 为代理路径前缀
- 路径格式：`/fullstack/{projectId}/`
- 确保 trailing slash

---

## 2026-06-01: iOS WebView 调试：客户端日志不可见时用服务端中转

**Symptom**: iOS Safari WebView 中的 `console.log` 无法直接查看（需要 Mac Safari Web Inspector 连接），调试 iframe 内问题时无法获取客户端日志。

**Investigation**:
- 尝试在 iOS 上打开 Safari Web Inspector — 需要 Mac + USB 连接，条件不具备
- 客户端代码中的调试日志只在浏览器控制台可见

**Root cause**: iOS Safari 的开发者工具需要物理连接 Mac，远程调试受限。

**Fix**: 在客户端加 `fetch('/api/debug-log', { method: 'POST', body: JSON.stringify({ logs }) })` 将日志发到服务器端，服务器用 `console.log` 输出。客户端用定时器批量发送，避免频繁请求。

**How to apply**:
- 调试 iOS/移动端 WebView 问题时，优先加服务端日志收集端点
- 客户端用数组缓存日志，定时批量 POST 到服务器
- 调试完成后必须清理调试代码（API 端点 + 客户端日志收集器）
- 也可用于远程调试无物理访问的设备
