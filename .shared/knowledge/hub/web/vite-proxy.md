# Vite 代理问题

## 2026-05-27: WS 代理对 iframe 请求静默失效 🔴

**现象**: iframe 内 WebSocket 连接 `/ws/monitor` 超时，readyState 停在 CONNECTING，主页面正常。

**排查**: curl 资源正常 → Node.js 直连正常 → 主页面 WS 正常 → iframe WS 超时 → 移除 sandbox 仍超时 → 直连 3001 正常 → 定位到 Vite 代理层。

**根因**: `/fullstack` 规则无 `ws: true`，拦截了 iframe 的 WS 升级请求但不转发。

**修复**: vite.config.ts 给 `/fullstack` 加 `ws: true`。

```typescript
'/fullstack': { target: 'https://localhost:3001', ws: true, secure: false },
```

**经验**: Vite WS 代理的 `ws: true` 不会穿透到其他代理规则，iframe 通过代理链加载时所有中间规则都需支持 WS。

---

## 2026-05-27: 代理规则前缀匹配冲突 🟡

**现象**: 将 WS 路径改为 `/fullstack/{id}/ws/monitor` 仍超时。

**根因**: Vite 按最长前缀匹配，`/fullstack/xxx/ws/monitor` 匹配了 `/fullstack` 规则而非 `/ws/monitor`。

**修复**: 给 `/fullstack` 加 `ws: true`，或使用不以 `/fullstack/` 开头的 WS 路径。

**经验**: Vite 代理匹配是最长前缀优先，非定义顺序优先。设计 WS 路径时避免与其他规则前缀冲突。

---

## 2026-06-01: Vite HMR WS 失败触发 iframe 全页刷新循环 🔴

**现象**: iframe 加载 Vite dev server 页面后，页面反复完整刷新（所有资源重新请求），形成闪烁循环。

**排查**: 服务器日志显示同一组资源（HTML + JS + CSS）被反复请求 → 无 `location.reload()` → 定位到 Vite HMR 客户端行为。

**根因**: Vite HMR 客户端在 WebSocket 连接失败时，会触发 full page reload 作为回退。当代理链中 WS 协议不匹配（如 `ws://` 代理到 HTTPS 服务器）导致连接持续失败时，每次 reload 后 HMR 再次失败，形成死循环。

**修复**: 确保 WebSocket 代理协议与上游服务器匹配（`wss://` 代理 HTTPS 上游）。

**经验**: iframe 中加载 Vite dev server 时，HMR WebSocket 代理链的每一层都必须正确配置。协议不匹配不会报明显错误，只会表现为页面反复刷新。

---

## 2026-06-06: Vite 代理正确转发 COOP/COEP 头 ✅

- **标签**: #vite #proxy #COOP #COEP #cross-origin
- **验证**: Vite dev proxy（`secure: false`）会完整转发上游的 `Cross-Origin-Opener-Policy` 和 `Cross-Origin-Embedder-Policy` 响应头。头名称会被小写化（HTTP/2 规范），但浏览器按 case-insensitive 处理，不影响功能。
- **如何应用**: Godot WASM 等需要跨域隔离的资源通过 Vite 代理加载时，无需额外配置，上游设置的 COOP/COEP 头会自动透传。

---

## 2026-06-06: Vite HTTPS dev server + 后端 CORS origin 不匹配导致 403 ⚠️

- **标签**: #vite #cors #https #proxy
- **症状**: 浏览器通过 Vite HTTPS dev server（`https://127.0.0.1:5173`）发 API 请求，后端返回 403 "Origin not allowed"。curl 直接请求后端正常。
- **排查**: curl 直连后端 201 → curl 经 Vite 代理 201 → 浏览器 fetch 403 → 检查 CORS 配置发现只有 `http://127.0.0.1:5173`
- **根因**: Vite dev server 使用 HTTPS 时，浏览器发送 `Origin: https://127.0.0.1:5173`。后端 CORS 白名单只配了 HTTP 版本，HTTPS origin 被拒绝。
- **修复**: 后端 CORS 配置同时添加 HTTP 和 HTTPS origin：`"http://127.0.0.1:5173", "https://127.0.0.1:5173"`
- **如何应用**: 只要 Vite 配了 HTTPS（自签证书等），后端 CORS 必须同时放行 `http://` 和 `https://` 两个 origin。curl 不受 CORS 限制所以测试正常，必须用浏览器验证。

---

## 2026-06-06: Vite 子路径下相对 fetch 路径错误 ⚠️

- **标签**: #vite #base #fetch #spa
- **症状**: `fetch("api/config")` 在 Vite dev server 子路径（`base: "/fullstack/mp4-to-frames/"`）下请求到错误路径，返回 404 或不触发代理。
- **根因**: 相对 URL `fetch("api/config")` 基于当前页面路径解析。页面在 `/fullstack/mp4-to-frames/` 时，实际请求变为 `/fullstack/mp4-to-frames/api/config`，不匹配 Vite 的 `/api` 代理规则。
- **修复**: 所有 API 调用使用绝对路径 `fetch("/api/config")` 而非相对路径 `fetch("api/config")`。
- **如何应用**: 当 Vite 配置了 `base` 路径时，前端所有 fetch/EventSource URL 必须用 `/api/...` 绝对路径。开发环境（根路径 `/`）下相对路径碰巧能用，部署到子路径就出问题——这是个隐蔽的环境差异 bug。
