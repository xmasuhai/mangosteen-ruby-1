# spec/support/rspec_api_documentation.rb
# 修复 rspec_api_documentation 与 Rack 3 / rack-test 2.2 的兼容问题。
#
# 现象：Rack 3 / rack-test 2.2 在 GET 等无请求体的请求中，不会向 env
# 中写入 `rack.input`，导致 `last_request.env["rack.input"]` 为 nil。
# rspec_api_documentation 6.1.0 的 ClientBase#read_request_body 会直接对其
# 调用 `rewind`，抛出：
#   NoMethodError: undefined method `rewind' for nil:NilClass
#   input.rewind
#
# 处理：当 rack.input 为 nil 时返回空字符串，避免对 nil 调用 rewind；
# 非 nil 时保持原有 rewind + read 行为。
module RspecApiDocumentation
  class ClientBase
    def read_request_body
      input = last_request.env["rack.input"]
      return "" if input.nil?

      input.rewind
      input.read
    end
  end
end
