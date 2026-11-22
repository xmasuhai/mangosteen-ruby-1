# Acceptance 测试 Skills 说明

本文档面向接手或维护 `spec/acceptance/` 目录下测试代码的开发者，说明如何正确引入、维护和排查 `rspec_api_documentation` 相关的 acceptance 测试。

## 一、为什么必须引入 `spec/support/` 的补丁

### 现有代码
- `spec/acceptance/items_spec.rb`：使用 `rspec_api_documentation/dsl` 的 `resource` / `get` / `example` / `do_request` 定义对 `GET /api/v1/items` 的 acceptance 测试（文件第 1-12 行）。
- `spec/support/rspec_api_documentation.rb`：对第三方库 `RspecApiDocumentation::ClientBase` 的 `read_request_body` 做了空值保护补丁（文件第 13-22 行）。
- `spec/rails_helper.rb` 第 26 行：`spec/support/**/*.rb` 目前**未自动 require**（被注释），需在 acceptance 规范文件中手动 `require_relative '../support/rspec_api_documentation'`。
- `config/routes.rb` 第 11 行：`resources :items, exclude: [ :put ]` 已注册 `/api/v1/items` 路由。

### 缺少补丁时的失败表现
运行 `spec/acceptance/items_spec.rb` 时，会抛出：

```
NoMethodError:
  undefined method `rewind' for nil:NilClass
        input.rewind
```

失败点位于 `rspec_api_documentation` 库的 `ClientBase#read_request_body`（`/usr/local/rvm/gems/ruby-3.1.2/gems/rspec_api_documentation-6.1.0/lib/rspec_api_documentation/client_base.rb` 第 47-50 行），在 `do_request` 完成请求后调用 `document_example` -> `read_request_body` 时触发。

### 根因
`rspec_api_documentation` 6.1.0 使用 `rack-test` 发请求，并在请求完成后从 `last_request.env["rack.input"]` 读取请求体并调用 `rewind`。项目实际安装的 `rack` 是 `3.2.7`、`rack-test` 是 `2.2.0`（`Gemfile.lock` 第 168-173 行）。Rack 3 / rack-test 2.2 在 GET 等无请求体请求中**不会向 env 写入 `rack.input`**，导致 `last_request.env["rack.input"]` 为 `nil`，库未做空值保护就直接调用 `rewind`，因而抛出 `NoMethodError`。

### 影响范围
- 所有使用 `rspec_api_documentation/dsl` 并调用 `do_request` 的 acceptance 测试均可能触发，不限于 GET；只要该次请求的 `env` 中没有 `rack.input` 就会失败。
- 该项目目前仅 `spec/acceptance/items_spec.rb` 一份 acceptance 测试，后续新增同类测试若复用 `do_request` 同样需要补丁生效。

### 不引入补丁的代价
- Acceptance 测试无法通过，CI 红，无法回归 `/api/v1/items` 接口的可用性。
- 即便接口本身正常，测试也会在断言 `expect(status).to eq 200` 之前因 `NoMethodError` 中止，失去验证意义。

---

## 二、如何引入补丁

### 涉及文件
| 路径 | 说明 |
|------|------|
| `spec/support/rspec_api_documentation.rb` | 新增，`RspecApiDocumentation::ClientBase#read_request_body` 的空值保护补丁 |
| `spec/acceptance/items_spec.rb` | 修改，在 `require 'rspec_api_documentation/dsl'` 之后增加 `require_relative '../support/rspec_api_documentation'` |

### 具体改动要点
1. 新建 `spec/support/rspec_api_documentation.rb`，重写 `read_request_body`：若 `input.nil?` 返回 `""`，否则保持原有 `input.rewind` + `input.read`（见文件第 15-21 行）。
2. 在 `spec/acceptance/items_spec.rb` 第 3 行显式 `require_relative '../support/rspec_api_documentation'`，因为 `spec/rails_helper.rb` 中 `spec/support` 自动 require 已被注释（见 rails_helper 第 26 行）。

### 前置条件
- 项目已执行 `bundle install`，`Gemfile` 已声明 `gem "rspec_api_documentation"`（Gemfile 第 35 行）。
- 测试数据库可达：`config/database.yml` test 环境默认 host 为 `db-for-mangosteen`（第 34 行），需提前启动该 PostgreSQL 容器（见 `README.md` 数据库创建章节），或本地临时将 `host` 指向可用的 PostgreSQL Unix Socket/地址。
- Ruby 3.1.2、Rails ~> 7.2.3（Gemfile 第 1、10 行）。

### 应用后的验证方式
运行 acceptance 测试，应通过：

```zsh
bundle exec rspec spec/acceptance/items_spec.rb
```

预期输出：

```
1 example, 0 failures
```

---

## 三、后续维护信息

### 常见问题与排查思路
1. 仍出现 `undefined method 'rewind' for nil:NilClass`：检查 acceptance 规范文件是否已 `require_relative '../support/rspec_api_documentation'`；若未引入，补丁不会加载。
2. `PG::ConnectionBad` 或 `ActiveRecord::DatabaseConnectionError`：确认 `db-for-mangosteen` PostgreSQL 容器已启动且 `config/database.yml` test 环境的 host/凭据可连通（`README.md` 数据库创建章节）。
3. 新增 acceptance 规范文件若使用 `resource` + `do_request`，需同步引入本补丁，否则无请求体请求（GET/HEAD 等）大概率失败。

### 回滚或移除补丁的条件与做法
- **回滚条件**：`rspec_api_documentation` 升级至已修复 Rack 3 / rack-test 2.2 兼容性的版本，或项目降级 rack/rack-test 到旧版本。
- **移除做法**：删除 `spec/support/rspec_api_documentation.rb`，并删除各 acceptance 规范文件中的 `require_relative '../support/rspec_api_documentation'` 行，恢复为仅 `require 'rails_helper'` + `require 'rspec_api_documentation/dsl'`。移除后需重新运行 `bundle exec rspec spec/acceptance/` 确认无回归。

### 需要注意的坑
- `spec/support/rspec_api_documentation.rb` 文件名**不能以 `_spec.rb` 结尾**，否则会被 RSpec 误当作规范文件执行并导致重复加载/报错（`rails_helper.rb` 第 15-16 行已说明）。
- `spec/rails_helper.rb` 中 `spec/support` 自动 require 被注释，不能依赖自动加载，必须在各 acceptance 规范文件中显式 `require_relative`。
- 补丁重写的是第三方库私有方法 `read_request_body`，库升级后需重新确认方法签名和实现是否变动，避免补丁失效或覆盖新行为。

---

### 结论基准

- 结论均基于已读取的实际代码文件（`spec/acceptance/items_spec.rb`、`spec/support/rspec_api_documentation.rb`、`spec/rails_helper.rb`、`config/routes.rb`、`Gemfile.lock`、`README.md`），未凭空推测。
- 测试结果基于 `rspec_api_documentation` 6.1.0
- 相关文件如有版本变动，需要重新评估和测试补丁是否仍然有效。

---
---
