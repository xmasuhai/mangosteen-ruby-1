# README

## 开发配置

### Ruby 版本

- `3.1.2`

### 系统依赖

- RubyGems `3.6.9`
- Bundler `2.6.9`（随 RubyGems 升级安装）

#### RubyGems 升级注意事项

> 旧版 RubyGems `3.3.7` 运行 `gem -v` 时会出现 `WARN: Unresolved or ambiguous specs during Gem::Specification.reset: tsort (>= 0)` 警告

- 原因：Ruby `3.1.2` 自带默认 gem `tsort 0.1.0`，而 Rails 依赖 `tsort >= 0.2`，项目又安装了 `tsort 0.2.0`，旧版 RubyGems 在两个版本间无法确定
- 该警告不影响功能，升级 RubyGems 即可消除

```zsh
gem update --system 3.6.9 --no-document
```

- 只能升级到 `3.6.9`：RubyGems `3.7` 及以上要求 Ruby `3.2+`，无法安装到 Ruby `3.1.2`
- 不要按警告提示执行 `gem cleanup tsort`，Rails 需要 `tsort 0.2.0`
- `Gemfile.lock` 中仍是 `BUNDLED WITH 2.3.7`，执行 `bundle install` 等命令后这一行可能被改写，提交前留意
- 升级只对当前机器生效，其他机器或 `Dockerfile` 构建的镜像若仍是 RubyGems `3.3.7`，需要同样执行一次升级命令

---

### 配置

### 数据库创建

> 在容器外部宿主机系统运行命令

```zsh
docker run -d --name db-for-mangosteen -e POSTGRES_USER=mangosteen -e POSTGRES_PASSWORD=123456 -e POSTGRES_DB=mangosteen_dev -e PGDATA=/var/lib/postgresql/data/pgdata -v mangosteen-data:/var/lib/postgresql/data -p 5432:5432 --network=network1 postgres:14
```

### Database initialization

> 在容器外部系统运行命令

```zsh
docker start db-for-mangosteen
```

---

## 启动本地服务

```zsh
bin/rails s
```

- 默认端口 `3000` 转发 `http://127.0.0.1:3000`

> 本地启动控制台运行命令

```zsh
bin/rails c
```

---

## 启动测试

```zsh
bin/rake docs:generate
```

---

## 查看生成api文档网页

```zsh
pnpx http-server doc/api/.
# 或者
cd ./doc/api/
npx http-server .
```

---

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

---
