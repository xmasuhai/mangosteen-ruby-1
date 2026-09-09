# README

## 开发配置

### Ruby 版本

- `3.1.2`

### 系统依赖

### 配置

### 数据库创建

> 在容器外部系统运行命令

```zsh
docker run -d --name db-for-mangosteen -e POSTGRES_USER=mangosteen -e POSTGRES_PASSWORD=123456 -e POSTGRES_DB=mangosteen_dev -e PGDATA=/var/lib/postgresql/data/pgdata -v mangosteen-data:/var/lib/postgresql/data -p 5432:5432 --network=network1 postgres:14
```

### Database initialization

> 在容器外部系统运行命令

```zsh
docker start db-for-mangosteen
```

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
