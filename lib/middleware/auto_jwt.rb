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
  # @return [Array]
  def call(env)
    header = env["HTTP_AUTHORIZATION"]
    if header.present?
      jwt = header.split(" ")[1] rescue ""
      payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: "HS256" }
      env["current_user_id"] = payload[0]["user_id"] rescue nil
    end
    @status, @headers, @response = @app.call(env)
    [ @status, @headers, @response ]
  end
end
