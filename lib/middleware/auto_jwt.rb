require "set"

class AutoJwt
  # 初始化中间件.
  # @param [Object] app Param documentation.
  # @return [Object]
  def initialize(app)
    @app = app
  end

  # 从请求头中获取 jwt，并解析.
  # @param [Object] env Param documentation.
  # @raise [StandardError]
  # @raise [JWT::ExpiredSignature]
  # @return [Array]
  def call(env)
    # 跳过 JWT 解析
    return @app.call(env) if SKIP_JWT_PATHS.include? env["PATH_INFO"]
    header = env["HTTP_AUTHORIZATION"]
    jwt = header.split(" ")[1] rescue ""
    begin
      payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: "HS256" }
    rescue JWT::ExpiredSignature
      return [ Rack::Utils.status_code(:unauthorized), {}, [ JSON.generate({ reason: "Token Expired" }) ] ]
    rescue
      return [ Rack::Utils.status_code(:unauthorized), {}, [ JSON.generate({ reason: "Token Invalid" }) ] ]
    end
    env["current_user_id"] = payload[0]["user_id"] rescue nil
    @status, @headers, @response = @app.call(env)
    [ @status, @headers, @response ]
  end

  # 定义白名单常量，使用 %w[...] 写字符串数组更简洁，.freeze 防止内容被篡改
  SKIP_JWT_PATHS = Set.new(%w[
    /api/v1/session
    /api/v1/validation_codes
  ].freeze)
end
