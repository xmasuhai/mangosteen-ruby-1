# Windows 下 Rails 启动排错记录（Bundler / Gem 版本平台问题）

> 环境：Windows + Ruby 3.1/3.2（x64-mingw-ucrt）、Rails 7.2.3.2、Bundler 2.3.7
> 目标：让 `bundle exec rails server` 正常启动

---

## 一、总体排错思路

整个过程遇到了三个相互关联的报错，排查顺序是「先修工具链，再修依赖解析，最后验证启动」：

```
1) Gem::Source 未初始化（bundler 自身崩溃）
        ↓
2) Could not find nokogiri-1.18.10（lock 缺平台）
        ↓
3) bundle exec rails server 报错（tzinfo-data 未被解析到）
        ↓
4) 验证：bundle check / rails runner / rails server --help
```

核心方法论：

1. **看栈顶而不是栈底**。栈底是 `bin/bundle`，但真正的错误发生在 RubyGems/Bundler 内部，说明问题在工具链而非应用代码。
2. **区分「工具链问题」和「依赖声明问题」**。前者靠升级 RubyGems/Bundler 或在 binstub 里补 require 解决；后者必须改 `Gemfile` / `Gemfile.lock`。
3. **用 Ruby 单行脚本直接问 Bundler**，不要靠猜。例如打印依赖展开结果、验证平台匹配：

   ```powershell
   ruby -e "require 'bundler'; defn = Bundler.definition; puts defn.send(:expand_dependencies, defn.dependencies, ['x64-mingw-ucrt']).map(&:inspect)"
   ruby -e "require 'bundler'; dep = Bundler.definition.dependencies.find { |d| d.name == 'tzinfo-data' }; p dep.platforms"
   ruby -e "require 'bundler'; p Bundler::MatchPlatform.platforms_match?([:x64_mingw], Gem::Platform.new('x64-mingw-ucrt'))"
   ```
4. **不确定方法名时，先定位源码**：

   ```powershell
   ruby -e "require 'bundler'; puts Bundler::MatchPlatform.method(:platforms_match?).source_location"
   ```

---

## 二、问题一：`uninitialized constant Gem::Source (NameError)`

### 现象

```
bundler/rubygems_ext.rb:18:in `source': uninitialized constant Gem::Source (NameError)
...
kernel_require.rb:167: CRITICAL: RUBYGEMS_ACTIVATION_MONITOR.owned?: before false -> after true (RuntimeError)
```

### 原因

- Bundler 在 `rubygems_ext.rb` 里调用 `Gem::Source::Installed.new`，但在 Ruby 3.1 + Bundler 2.3.x 早期版本中 `rubygems/source` 没有被提前 require，遍历未解析依赖树时就抛出 `NameError`。
- 该异常打断了嵌套的 `require` 链，导致 Ruby 3.1 新引入的 `RUBYGEMS_ACTIVATION_MONITOR` 锁状态不一致，于是又抛出后面那个 `CRITICAL ... RuntimeError`。**第二个错误是第一个错误的副作用，不要单独去查它。**

### 处理

首选升级工具链（根治）：

```powershell
gem update --system
gem install bundler
bundle update --bundler   # 同步 Gemfile.lock 里的 BUNDLED WITH
```

若暂时无法升级，在 `bin/bundle` 顶部补一行兜底：

```ruby
require "rubygems"
require "rubygems/source"
```

---

## 三、问题二：`Could not find nokogiri-1.18.10 in any of the sources`

### 现象

```powershell
bin/rails -v
# Could not find nokogiri-1.18.10 in any of the sources
```

### 原因

`Gemfile.lock` 里只写了纯 Ruby 版的 `nokogiri (1.18.10)`（需要本地编译），而本机安装的是**预编译平台包** `nokogiri-1.18.10-x64-mingw-ucrt`。Bundler 严格按 lock 里的 spec 名 + 平台匹配，找不到就直接报错。

### 处理

在 `Gemfile.lock` 的 `specs:` 中补上平台化的 spec（注意平台包**不依赖** `mini_portile2`）：

```
    nokogiri (1.18.10-x64-mingw-ucrt)
      racc (~> 1.4)
    nokogiri (1.18.10-x86_64-linux)
      racc (~> 1.4)
```

并确认 `PLATFORMS` 段包含：

```
PLATFORMS
  x64-mingw-ucrt
  x86_64-linux
```

---

## 四、问题三：`bundle exec rails server` 报错（tzinfo-data）

### 原因

Rails 默认生成的写法是：

```ruby
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]
```

在当前 Bundler 2.3.7 上，这些平台符号**都无法**匹配 `x64-mingw-ucrt`（已实测 `windows / mingw / x64_mingw / ucrt / x64_mingw_ucrt / mswin` 全部返回 `false`）。结果 `tzinfo-data` 被当作「本平台不需要」而不解析，运行期缺少时区数据。

### 处理

1. `Gemfile`：去掉平台限制。

   ```ruby
   # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
   gem "tzinfo-data"
   ```
2. `Gemfile.lock`：补上对应 spec 与依赖声明。

   ```
       tzinfo-data (1.2026.3)
         tzinfo (>= 1.0.0)
   ```

   同时确保 `DEPENDENCIES` 段含 `tzinfo-data`。

---

## 五、验证步骤

```powershell
ruby bin/bundle check                              # => The Gemfile's dependencies are satisfied
ruby bin/rails runner "puts Rails.version; puts 'OK'"  # => 7.2.3.2 / OK
bundle exec rails server --help                    # 正常输出参数说明
```

---

## 六、关键注意点（Checklist）

- [ ] **命令是 `bundle exec`，不是 `bundle exe`**（`exe` 只是恰好被前缀匹配到 `exec`，不要依赖）。
- [ ] **同时排查栈里出现的所有异常，但只修根因**：`RUBYGEMS_ACTIVATION_MONITOR` 类错误几乎总是前一个异常的连带产物。
- [ ] **Ruby 版本要和 gem 目录对上**。本机存在 `Ruby31_2-x64` 与 `Ruby32-x64` 两套安装，报错栈里的路径与实际执行的 `ruby` 可能不是同一套，先 `ruby -v` / `gem env` 确认。
- [ ] **Windows 平台名是 `x64-mingw-ucrt`**（Ruby ≥ 3.1）。旧的 `x64-mingw32` / `x64_mingw` 符号不再匹配，凡是 `platforms:` 限定都要重新验证。
- [ ] **预编译 gem 的 lock spec 必须带平台后缀**，且依赖列表与纯 Ruby 版不同（少了编译相关依赖如 `mini_portile2`）。
- [ ] **跨平台协作时 `PLATFORMS` 要同时列出开发机与部署机**（如 `x64-mingw-ucrt` + `x86_64-linux`），否则 CI/Docker 里会重现同类错误。
- [ ] **手改 `Gemfile.lock` 只是应急手段**，条件允许时优先用 `bundle lock --add-platform x86_64-linux` / `bundle install` 让 Bundler 自己生成。
- [ ] **升级 Bundler 后记得同步 `BUNDLED WITH`**（当前仍为 `2.3.7`），否则 binstub 会去激活一个旧版本。
- [ ] **改完任何一处都跑一次 `bundle check`**，用最快的命令确认是否还有未满足依赖，再去跑更重的启动流程。
