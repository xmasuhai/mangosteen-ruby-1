# Rails 路由与控制器单复数规则

本项目是 Rails 7.2、`config.api_only = true` 的 API 项目，测试用 RSpec。
在编写或修改路由、控制器、生成器命令时，请遵守以下规则。

## 核心原则

- 控制器类名一律用复数：`SessionsController`、`ValidationCodesController`。
- 用 `resources` 还是 `resource`，取决于资源是否需要 `:id` 来区分个体。
- 模型类名用单数（`ValidationCode`），对应的表名是复数（`validation_codes`）。

## 路由：`resources`（复数资源）

用于有很多个、需要用 `:id` 区分的资源，例如 `resources :items`。

| 请求 | 路径 | 控制器#动作 |
|---|---|---|
| GET | `/items` | `items#index` |
| POST | `/items` | `items#create` |
| GET | `/items/:id` | `items#show` |
| PATCH/PUT | `/items/:id` | `items#update` |
| DELETE | `/items/:id` | `items#destroy` |

- 路径和控制器名都直接使用你写的名字，**不做单复数转换**。
- 所以名字必须写复数：`resources :items`、`resources :validation_codes`。

## 路由：`resource`（单数资源）

用于当前上下文中只有一个、不需要 `:id` 的资源，例如 `resource :session`（当前用户的登录会话）。

| 请求 | 路径 | 控制器#动作 |
|---|---|---|
| POST | `/session` | `sessions#create` |
| GET | `/session` | `sessions#show` |
| PATCH/PUT | `/session` | `sessions#update` |
| DELETE | `/session` | `sessions#destroy` |

- 路径是单数，没有 `:id`，也没有 `index`。
- 控制器名会**自动转成复数**：`resource :session` 对应 `SessionsController`。
- 名字写单数：`resource :session`、`resource :profile`、`resource :me`。

## 动作数量

- 本项目是 API 模式，不生成 `new` 和 `edit`：`resources` 有 5 个动作，`resource` 有 4 个。
- 非 API 模式下才是 7 个和 6 个，并且有 `/items/:id/edit` 这类路径。

## 对照表

| 写法 | 路径 | 找的控制器 | 结果 |
|---|---|---|---|
| `resources :sessions` | `/sessions`、`/sessions/:id` | `SessionsController` | 正确 |
| `resource :session` | `/session` | `SessionsController` | 正确 |
| `resources :session` | `/session`、`/session/:id` | `SessionController` | 找不到控制器 |
| `resource :sessions` | `/sessions` | `SessionsController` | 能用，但不合约定 |

## 命名空间

```ruby
namespace :api do
  namespace :v1 do
    resources :validation_codes, only: [ :create ]
    resource :session, only: [ :create, :destroy ]
  end
end
```

- 路径加上 `/api/v1` 前缀，控制器加上 `Api::V1::` 模块前缀。
- 单复数规则不变。

## 生成器：`bin/rails g controller`

格式：`bin/rails g controller 名字 [动作...]`

- **名字要自己写复数**，生成器不会转换，写什么就生成什么。
  - `bin/rails g controller api/v1/sessions` 生成 `app/controllers/api/v1/sessions_controller.rb`，类名 `Api::V1::SessionsController`。
  - `bin/rails g controller api/v1/session` 生成 `session_controller.rb`，类名 `Api::V1::SessionController`，不合约定。
- **不需要加 `_controller` 后缀**。加了也会被自动去掉，`api/v1/users_controller` 和 `api/v1/users` 结果相同，不会生成 `users_controller_controller.rb`。
- **斜杠表示命名空间**：`api/v1/sessions` 对应目录 `api/v1/` 和模块 `Api::V1::`，也可以写成 `Api::V1::Sessions`。
- **后面可以跟动作名**：`bin/rails g controller api/v1/sessions create destroy` 会生成这两个空方法。
- **带动作名时加上 `--skip-routes`**。否则它会往 `config/routes.rb` 里加 `get 'sessions/create'` 这种路由，需要手动删掉再换成 `resource`/`resources`。
- 会同时生成 RSpec 测试文件 `spec/requests/api/v1/sessions_spec.rb`。
- 不确定会生成什么时，加 `--pretend` 只预览、不写文件。

## 单复数速查

| 东西 | 单复数 | 例子 |
|---|---|---|
| 模型类 | 单数 | `ValidationCode` |
| 数据库表 | 复数 | `validation_codes` |
| 控制器类 | 复数 | `ValidationCodesController` |
| `resources` 路由 | 复数 | `resources :validation_codes` |
| `resource` 路由 | 单数 | `resource :session` |

## 排查方法

- 运行 `bin/rails routes`，查看每条路由实际对应的路径和 `控制器#动作`。
- 测试环境设置了 `config.action_dispatch.show_exceptions = :rescuable`，找不到控制器时请求返回 404 而不是抛异常。
- 遇到意外的 404，先看 `log/test.log` 里有没有 `uninitialized constant Api::V1::XxxController`，有就说明路由的单复数写错了。
