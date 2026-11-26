# Rack env 自定义属性规范文档

## 概述

- 本文档记录了项目中向 Rack `env` 哈希写入的所有自定义属性，以及常用的默认 Rack 环境属性。
- 旨在统一中间件、控制器、测试代码对 `env` 的读写约定，避免键名冲突和类型不一致。
- 一旦版本变更，在 `env` 中添加、删除或修改属性时，请务必同步本文档；

---

## 自定义属性

### 1. `current_user_id`

| 维度 | 说明 |
|------|------|
| **属性名** | `current_user_id` |
| **数据类型** | `Integer \| nil` |
| **来源模块** | `AutoJwt` 中间件 (`lib/middleware/auto_jwt.rb`) |
| **写入时机** | 中间件 `call(env)` 执行期间，仅当 `HTTP_AUTHORIZATION` 头存在且 JWT 解码成功时 |
| **写入代码位置** | `lib/middleware/auto_jwt.rb:18` |
| **消费代码位置** | `app/controllers/api/v1/mes_controller.rb:8` (`Api::V1::MesController#show`) |
| **读取方式** | `request.env["current_user_id"]` 或 `env["current_user_id"]` |
| **示例值** | `42` (用户 ID), `nil` (无有效 JWT 或无 Authorization 头) |
| **注意事项** | - 仅在 JWT 合法且包含 `user_id` 时写入<br>- JWT 解码失败或 payload 无 `user_id` 时写入 `nil`<br>- 中间件不拦截请求，始终调用 `@app.call(env)` 继续执行<br>- 控制器需自行处理 `nil` 情况（如返回 403） |

**写入逻辑源码**：
```ruby
# lib/middleware/auto_jwt.rb:14-19
header = env["HTTP_AUTHORIZATION"]
if header.present?
  jwt = header.split(" ")[1] rescue ""
  payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: "HS256" }
  env["current_user_id"] = payload[0]["user_id"] rescue nil
end
```

**读取逻辑源码**：
```ruby
# app/controllers/api/v1/mes_controller.rb:8-10
user_id = request.env["current_user_id"] rescue nil
currentUser = User.find user_id
return render status: :forbidden, json: { errors: "Invalid JWT" } if currentUser.nil?
```

---

## 常用默认 Rack env 属性（参考）

以下为 Rack 规范及 Rails 常用的标准环境键，供开发时参考避免冲突：

| 属性名 | 数据类型 | 来源 | 说明 |
|--------|----------|------|------|
| `REQUEST_METHOD` | `String` | Rack/Web 服务器 | HTTP 方法：`GET`, `POST`, `PUT`, `DELETE` 等 |
| `SCRIPT_NAME` | `String` | Rack | 应用挂载路径前缀（通常为空或 `/`） |
| `PATH_INFO` | `String` | Rack | 请求路径（不含查询字符串），如 `/api/v1/me` |
| `QUERY_STRING` | `String` | Rack | 原始查询字符串，如 `page=1&per=20` |
| `SERVER_NAME` | `String` | Rack | 服务器主机名 |
| `SERVER_PORT` | `String` | Rack | 服务器端口 |
| `SERVER_PROTOCOL` | `String` | Rack | 协议版本，如 `HTTP/1.1` |
| `rack.version` | `Array[Integer]` | Rack | Rack 协议版本，如 `[1, 3]` |
| `rack.url_scheme` | `String` | Rack | `http` 或 `https` |
| `rack.input` | `IO-like` | Rack | 请求体输入流 |
| `rack.errors` | `IO-like` | Rack | 错误输出流 |
| `rack.multithread` | `Boolean` | Rack | 是否多线程环境 |
| `rack.multiprocess` | `Boolean` | Rack | 是否多进程环境 |
| `rack.run_once` | `Boolean` | Rack | 是否单次运行（如 CGI） |
| `HTTP_*` | `String` | Rack | HTTP 请求头，键名大写、下划线、前缀 `HTTP_`，如 `HTTP_AUTHORIZATION`, `HTTP_ACCEPT` |
| `CONTENT_TYPE` | `String` | Rack | 请求体 Content-Type（无 `HTTP_` 前缀） |
| `CONTENT_LENGTH` | `String` | Rack | 请求体长度（无 `HTTP_` 前缀） |
| `action_dispatch.request.parameters` | `Hash` | Rails | 合并后的路由/查询/请求体参数 |
| `action_dispatch.request.path_parameters` | `Hash` | Rails | 路由匹配参数（如 `:id`, `:controller`, `:action`） |
| `action_dispatch.request.request_parameters` | `Hash` | Rails | 请求体参数（POST/PUT body） |
| `action_dispatch.request.query_parameters` | `Hash` | Rails | 查询字符串参数 |
| `action_dispatch.request.content_type` | `String` | Rails | 解析后的 Content-Type |
| `action_dispatch.request.formats` | `Array<Mime::Type>` | Rails | 接受的响应格式 |
| `action_dispatch.request.headers` | `ActionDispatch::Http::Headers` | Rails | 请求头对象（可直接用 `request.headers`） |
| `action_dispatch.request.remote_ip` | `String` | Rails | 客户端 IP（经代理处理） |
| `action_dispatch.request.uuid` | `String` | Rails | 请求唯一标识 (request_id) |
| `action_dispatch.routes` | `ActionDispatch::Routing::RouteSet` | Rails | 路由集合 |
| `warden` | `Warden::Proxy` | Warden/Devise | 认证代理对象（如使用 Devise） |
| `devise.skip_trackable` | `Boolean` | Devise | 是否跳过 trackable 更新 |

---

## 命名约定建议

1. **前缀命名空间**：自定义属性建议使用项目/业务前缀，如 `mangosteen.current_user_id`，避免与第三方中间件冲突
2. **类型一致性**：同一键在所有写入点保持相同数据类型
3. **文档同步**：新增自定义 `env` 键时，必须同步更新本文档
4. **只读约定**：中间件写入、控制器/后续中间件只读；避免控制器反写 `env` 供前置中间件使用（时序问题）

---

## 变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-11-26 | 1.0 | 初始版本：记录 `current_user_id` 及常用默认属性 | Kilo |

---

## 源码引用

本文档引用并基于以下源码文件进行分析：

- `lib/middleware/auto_jwt.rb`
  - 链接: [https://github.com/xmasuhai/mangosteen-ruby-1/blob/main/lib/middleware/auto_jwt.rb](https://github.com/xmasuhai/mangosteen-ruby-1/blob/main/lib/middleware/auto_jwt.rb)
  - 说明: 定义 `AutoJwt` 中间件并向 `env` 写入 `current_user_id`
- `app/controllers/api/v1/mes_controller.rb`
  - 链接: [https://github.com/xmasuhai/mangosteen-ruby-1/blob/main/app/controllers/api/v1/mes_controller.rb](https://github.com/xmasuhai/mangosteen-ruby-1/blob/main/app/controllers/api/v1/mes_controller.rb)
  - 说明: 读取 `env` 中的 `current_user_id` 并查询用户

---

*文档位置：`prompts/docs/env_custom_attributes.md`*